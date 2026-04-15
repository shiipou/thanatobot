import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/thread.dart';
import '../models/app_settings.dart';
import '../models/realtime_event.dart';
import '../services/openai_service.dart';

// Custom audio source for streaming audio chunks as WAV
class _StreamingAudioSource extends StreamAudioSource {
  final StreamController<List<int>> _controller = StreamController();
  final List<int> _pcmBuffer = [];
  bool _headerSent = false;
  bool _isComplete = false;

  void addAudioChunk(Uint8List chunk) {
    if (_isComplete) return;

    _pcmBuffer.addAll(chunk);

    // Send header on first chunk
    if (!_headerSent) {
      _headerSent = true;
      // Send header with a large placeholder size (will be ignored in streaming)
      final header = _createWavHeader(999999999);
      _controller.add(header);
    }

    // Stream the audio data
    _controller.add(chunk);
  }

  void complete() {
    if (!_isComplete) {
      _isComplete = true;
      _controller.close();
    }
  }

  List<int> _createWavHeader(int dataSize) {
    return [
      // RIFF header
      0x52, 0x49, 0x46, 0x46, // 'RIFF'
      ...(_toLittleEndian(dataSize + 36, 4)), // File size - 8
      0x57, 0x41, 0x56, 0x45, // 'WAVE'
      // fmt chunk
      0x66, 0x6D, 0x74, 0x20, // 'fmt '
      0x10, 0x00, 0x00, 0x00, // Chunk size (16 bytes)
      0x01, 0x00, // Audio format (PCM = 1)
      0x01, 0x00, // Num channels (mono = 1)
      ..._toLittleEndian(24000, 4), // Sample rate (24000)
      ..._toLittleEndian(48000, 4), // Byte rate (24000 * 1 * 2)
      0x02, 0x00, // Block align (1 * 2)
      0x10, 0x00, // Bits per sample (16)
      // data chunk
      0x64, 0x61, 0x74, 0x61, // 'data'
      ...(_toLittleEndian(dataSize, 4)), // Data size
    ];
  }

  List<int> _toLittleEndian(int value, int bytes) {
    final result = <int>[];
    for (int i = 0; i < bytes; i++) {
      result.add((value >> (i * 8)) & 0xFF);
    }
    return result;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // For streaming, we return the stream directly
    return StreamAudioResponse(
      sourceLength: null, // Unknown length for streaming
      contentLength: null,
      offset: start ?? 0,
      stream: _controller.stream.map((chunk) => Uint8List.fromList(chunk)),
      contentType: 'audio/wav',
    );
  }
}

class VoiceCallPage extends StatefulWidget {
  final Thread thread;
  final AppSettings settings;

  const VoiceCallPage({
    super.key,
    required this.thread,
    required this.settings,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  AudioRecorder? _audioRecorder;
  final _audioPlayer = AudioPlayer();

  OpenAIService? _openAI;
  StreamSubscription<RealtimeEvent>? _eventSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  bool _isConnected = false;
  bool _isRecording = false;
  bool _isConnecting = false;
  bool _isDisposed = false;

  final List<String> _userTranscripts = [];
  final List<String> _assistantTranscripts = [];
  final _scrollController = ScrollController();

  String _connectionStatus = 'Not connected';
  bool _isSpeaking = false;
  bool _isAISpeaking = false;

  // Audio streaming for playback
  _StreamingAudioSource? _streamingAudioSource;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Initialize the audio recorder
    _audioRecorder = AudioRecorder();

    _openAI = OpenAIService(
      apiKey: widget.settings.apiKey,
      assistantId: widget.settings.assistantId,
    );

    await _connectToRealtime();
  }

  String? fileSearch;
  Future<void> _connectToRealtime() async {
    if (_openAI == null) return;

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      // Get assistant instructions
      String? instructions;
      List<Map<String, dynamic>>? realtimeTools;
      try {
        final assistant = await _openAI!.getAssistant();
        instructions = assistant['instructions'] as String?;

        final assistantTools =
            assistant['tool_resources'] as Map<String, dynamic>?;

        // Check if assistant has file_search tool
        fileSearch =
            (assistantTools?['file_search']['vector_store_ids']
                    as List<String>?)
                ?.firstOrNull;

        debugPrint('Assistant file_search: $fileSearch');

        if (fileSearch != null) {
          // Convert file_search to a custom function for Realtime API
          realtimeTools = [
            {
              'type': 'function',
              'name': 'search_knowledge_base',
              'description':
                  'Search through the knowledge base and documents to find relevant information. Use this when the user asks questions that might be answered by uploaded files or documents.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'description':
                        'The search query or question to find in the knowledge base',
                  },
                },
                'required': ['query'],
              },
            },
          ];
          debugPrint('Configured realtime tools: $realtimeTools');
        }

        debugPrint('Using assistant instructions: $instructions');
      } catch (e) {
        debugPrint('Failed to get assistant configuration: $e');
        instructions =
            'You are a helpful voice assistant. Be concise and natural.';
      }

      await _openAI!.connectRealtime(
        model: 'gpt-realtime',
        voice: widget.settings.voice,
        instructions: instructions,
        tools: realtimeTools,
      );

      _eventSubscription = _openAI!.realtimeEvents?.listen(
        _handleRealtimeEvent,
      );

      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connected';
      });

      // Start recording automatically
      await _startRecording();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed';
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _handleRealtimeEvent(RealtimeEvent event) async {
    debugPrint('Received event: ${event.type}');

    switch (event.type) {
      case 'session.created':
      case 'session.updated':
        setState(() => _connectionStatus = 'Session active');
        break;

      case 'input_audio_buffer.speech_started':
        setState(() => _isSpeaking = true);
        print('Speech started');
        break;

      case 'input_audio_buffer.speech_stopped':
        setState(() => _isSpeaking = false);
        print('Speech stopped');
        break;

      case 'conversation.item.input_audio_transcription.completed':
        final transcript = event.data['transcript'] as String?;
        print('User transcript: $transcript');
        if (transcript != null && transcript.isNotEmpty) {
          setState(() {
            _userTranscripts.add(transcript);
          });
          _scrollToBottom();
        }
        break;

      case 'response.output_audio_transcript.delta':
        final delta = event.data['delta'] as String?;
        if (delta != null && delta.isNotEmpty) {
          print('Assistant transcript delta: $delta');
          setState(() {
            if (_assistantTranscripts.isEmpty) {
              _assistantTranscripts.add(delta);
            } else {
              _assistantTranscripts[_assistantTranscripts.length - 1] += delta;
            }
          });
          _scrollToBottom();
        }
        break;

      case 'response.output_audio_transcript.done':
        // Start a new transcript entry for the next response
        final transcript = event.data['transcript'] as String?;
        print('Assistant transcript complete: $transcript');
        setState(() {
          if (_assistantTranscripts.isNotEmpty &&
              _assistantTranscripts.last.isNotEmpty) {
            // Transcript is complete, next one will be new
          }
        });
        break;

      case 'response.output_audio.delta':
        final audioBase64 = event.data['delta'] as String?;
        if (audioBase64 != null) {
          debugPrint('Received audio delta, length: ${audioBase64.length}');
          final audioData = base64Decode(audioBase64);
          debugPrint('Decoded audio chunk: ${audioData.length} bytes');

          // Mark that AI is speaking
          if (!_isAISpeaking) {
            setState(() => _isAISpeaking = true);
          }

          // Create streaming source and start playing on first chunk
          if (_streamingAudioSource == null) {
            _streamingAudioSource = _StreamingAudioSource();
            // Start playing immediately
            _startStreamingPlayback();
          }

          // Add audio chunk - will be streamed in real-time
          _streamingAudioSource!.addAudioChunk(Uint8List.fromList(audioData));
        }
        break;

      case 'response.output_audio.done':
        debugPrint('Audio response done');
        setState(() => _isAISpeaking = false);
        // Complete the stream
        _streamingAudioSource?.complete();
        break;

      case 'response.done':
        debugPrint('Response done');
        // Response completed
        if (_assistantTranscripts.isNotEmpty &&
            _assistantTranscripts.last.isNotEmpty) {
          // Prepare for next response
          setState(() {
            _assistantTranscripts.add('');
          });
        }
        break;

      case 'error':
        final error = event.data['error'];
        debugPrint('Error event: ${error['message']}');
        setState(() => _connectionStatus = 'Error: ${error['message']}');
        break;

      case 'response.function_call_arguments.done':
        // Function call is ready to be executed
        final callId = event.data['call_id'] as String?;
        final name = event.data['name'] as String?;
        final arguments = event.data['arguments'] as String?;

        if (callId != null && name != null && fileSearch != null) {
          debugPrint('Function call: $name($arguments)');
          await _handleFunctionCall(
            fileSearch!,
            callId,
            name,
            arguments ?? '{}',
          );
        }
        break;

      default:
        debugPrint('Unhandled event type: ${event.type}');
    }
  }

  Future<void> _handleFunctionCall(
    String vectorDatabaseId,
    String callId,
    String functionName,
    String argumentsJson,
  ) async {
    try {
      final arguments = jsonDecode(argumentsJson) as Map<String, dynamic>;

      if (functionName == 'search_knowledge_base') {
        final query = arguments['query'] as String;
        debugPrint('Searching knowledge base for: $query');

        // Show indicator
        if (mounted) {
          setState(() => _connectionStatus = 'Searching...');
        }

        // Perform search using assistant's file_search
        final result = await _openAI!.searchKnowledgeBase(
          vectorDatabaseId,
          query,
        );
        debugPrint('Search result: $result');

        // Send result back to the model
        _openAI!.sendFunctionCallOutput(
          callId: callId,
          output: jsonEncode({'result': result}),
        );

        if (mounted) {
          setState(() => _connectionStatus = 'Session active');
        }
      } else {
        debugPrint('Unknown function: $functionName');
        _openAI!.sendFunctionCallOutput(
          callId: callId,
          output: jsonEncode({'error': 'Unknown function: $functionName'}),
        );
      }
    } catch (e) {
      debugPrint('Error handling function call: $e');
      _openAI!.sendFunctionCallOutput(
        callId: callId,
        output: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<void> _startRecording() async {
    if (!_isConnected ||
        _isRecording ||
        _audioRecorder == null ||
        _isDisposed) {
      return;
    }

    try {
      if (await _audioRecorder!.hasPermission()) {
        final stream = await _audioRecorder!.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 24000,
            numChannels: 1,
          ),
        );

        setState(() => _isRecording = true);

        _audioStreamSubscription = stream.listen(
          (data) {
            if (_isConnected && _openAI != null && !_isDisposed) {
              _openAI!.sendAudio(Uint8List.fromList(data));
            }
          },
          onError: (error) {
            if (mounted && !_isDisposed) {
              setState(() => _isRecording = false);
            }
          },
          onDone: () {
            if (mounted && !_isDisposed) {
              setState(() => _isRecording = false);
            }
          },
        );
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _audioRecorder == null) return;

    try {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      await _audioRecorder!.stop();

      if (mounted && !_isDisposed) {
        setState(() => _isRecording = false);
      }

      // Clear audio buffer instead of committing (don't send to bot)
      _openAI?.clearAudioBuffer();
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      }
    }
  }

  void _startStreamingPlayback() async {
    if (_streamingAudioSource == null || _isDisposed) return;

    try {
      // Pause recording while bot is speaking
      final wasRecording = _isRecording;
      debugPrint('Starting playback, was recording: $wasRecording');

      if (wasRecording) {
        await _stopRecordingTemporarily();
      }

      // Set up and start playing immediately
      await _audioPlayer.setAudioSource(_streamingAudioSource!);
      await _audioPlayer.play();

      // Wait for completion
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );

      debugPrint('Playback completed');

      // Reset for next audio response
      _streamingAudioSource = null;

      // Resume recording after bot finishes speaking
      if (wasRecording && !_isDisposed && mounted) {
        debugPrint('Resuming recording after playback');
        await _startRecording();
      }
    } catch (e) {
      debugPrint('Error during streaming playback: $e');
      _streamingAudioSource = null;

      // Try to resume recording even on error
      if (!_isDisposed && mounted && !_isRecording) {
        debugPrint('Attempting to restart recording after error');
        await _startRecording();
      }
    }
  }

  Future<void> _stopRecordingTemporarily() async {
    if (!_isRecording || _audioRecorder == null) return;

    try {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      await _audioRecorder!.stop();

      if (mounted && !_isDisposed) {
        setState(() => _isRecording = false);
      }
    } catch (e) {
      debugPrint('Error stopping recording temporarily: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endCall() async {
    if (_isDisposed) return;

    _isDisposed = true;

    await _stopRecording();
    await _audioStreamSubscription?.cancel();
    await _audioRecorder?.dispose();
    await _audioPlayer.dispose();
    _eventSubscription?.cancel();
    _openAI?.disconnectRealtime();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _audioStreamSubscription?.cancel();
    _audioRecorder?.dispose();
    _audioPlayer.dispose();
    _eventSubscription?.cancel();
    _scrollController.dispose();
    _openAI?.disconnectRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Call'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end),
            onPressed: _endCall,
            color: Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isConnected
                ? Colors.green.withValues(alpha: .1)
                : Colors.grey.withValues(alpha: .1),
            child: Column(
              children: [
                Icon(
                  _isConnected ? Icons.phone_in_talk : Icons.phone_disabled,
                  size: 48,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  _connectionStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAISpeaking
                              ? 'Speaking...'
                              : _isSpeaking
                              ? 'Listening...'
                              : 'Idle',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Transcription area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _userTranscripts.length +
                  _assistantTranscripts.where((t) => t.isNotEmpty).length,
              itemBuilder: (context, index) {
                // Interleave user and assistant transcripts
                bool isUser;
                String transcript;

                // Determine if this is a user or assistant message
                int userIndex = 0;
                int assistantIndex = 0;
                for (int i = 0; i <= index; i++) {
                  if (i % 2 == 0 && userIndex < _userTranscripts.length) {
                    if (i == index) {
                      isUser = true;
                      transcript = _userTranscripts[userIndex];
                      break;
                    }
                    userIndex++;
                  } else {
                    final validAssistants = _assistantTranscripts
                        .where((t) => t.isNotEmpty)
                        .toList();
                    if (assistantIndex < validAssistants.length) {
                      if (i == index) {
                        isUser = false;
                        transcript = validAssistants[assistantIndex];
                        break;
                      }
                      assistantIndex++;
                    }
                  }
                }

                // Fallback
                if (index < _userTranscripts.length) {
                  isUser = true;
                  transcript = _userTranscripts[index];
                } else {
                  isUser = false;
                  final validAssistants = _assistantTranscripts
                      .where((t) => t.isNotEmpty)
                      .toList();
                  transcript = validAssistants[index - _userTranscripts.length];
                }

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transcript,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isConnected)
                  ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                    label: Text(_isRecording ? 'Stop' : 'Record'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_isConnecting) const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
