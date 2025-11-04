import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'realtime_constants.dart';

/// Client for OpenAI Realtime API with proper WebSocket header support
class OpenAIRealtimeClient {
  final String apiKey;
  final String model;
  final String voice;
  final String instructions;
  
  WebSocket? _socket;
  StreamSubscription? _subscription;
  bool _connected = false;
  bool _hasActiveResponse = false;
  bool _isSpeaking = false;
  
  // Callbacks for events
  Function(Uint8List)? _onAudioDelta;
  Function(String)? _onTranscriptDelta;
  Function()? _onResponseDone;
  Function()? _onSpeechStarted;
  Function()? _onSpeechStopped;
  Function(Map<String, dynamic>)? _onError;
  
  OpenAIRealtimeClient({
    required this.apiKey,
    this.model = RealtimeConstants.defaultModel,
    this.voice = RealtimeConstants.defaultVoice,
    this.instructions = RealtimeConstants.defaultInstructions,
  });
  
  bool get isConnected => _connected;
  bool get hasActiveResponse => _hasActiveResponse;
  bool get isSpeaking => _isSpeaking;
  
  /// Connect to OpenAI Realtime API with proper headers
  Future<void> connect() async {
    if (_connected) {
      return;
    }
    
    try {
      // Parse the URL
      final uri = Uri.parse('${RealtimeConstants.realtimeUrl}?model=$model');
      
      // Create headers for WebSocket connection
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'realtime=v1',
      };
      
      // Connect using dart:io WebSocket with custom headers
      _socket = await WebSocket.connect(
        uri.toString(),
        headers: headers,
      );
      
      _connected = true;
      
      // Start listening to messages
      _subscription = _socket!.listen(
        (message) {
          if (message is String) {
            _handleMessage(message);
          }
        },
        onError: (error) {
          _connected = false;
          _onError?.call({'message': error.toString()});
        },
        onDone: () {
          _connected = false;
        },
      );
      
      // Configure session
      await _configureSession();
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }
  
  /// Disconnect from OpenAI Realtime API
  Future<void> disconnect() async {
    if (!_connected) {
      return;
    }
    
    _connected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
  }
  
  /// Configure the session with desired settings
  Future<void> _configureSession() async {
    final sessionConfig = {
      'type': RealtimeConstants.eventTypeSessionUpdate,
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': instructions,
        'voice': voice,
        'input_audio_format': RealtimeConstants.audioFormat,
        'output_audio_format': RealtimeConstants.audioFormat,
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': RealtimeConstants.vadThreshold,
          'prefix_padding_ms': RealtimeConstants.vadPrefixPaddingMs,
          'silence_duration_ms': RealtimeConstants.vadSilenceDurationMs,
        },
      },
    };
    
    await _sendEvent(sessionConfig);
  }
  
  /// Send an event to the WebSocket
  Future<void> _sendEvent(Map<String, dynamic> event) async {
    if (!_connected || _socket == null) {
      throw Exception('WebSocket not connected');
    }
    
    try {
      final eventJson = jsonEncode(event);
      _socket!.add(eventJson);
    } catch (e) {
      throw Exception('Error sending event: $e');
    }
  }
  
  /// Handle incoming WebSocket messages
  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final eventType = data['type'] as String?;
      
      switch (eventType) {
        case RealtimeConstants.eventTypeResponseCreated:
          _hasActiveResponse = true;
          break;
          
        case RealtimeConstants.eventTypeResponseAudioDelta:
          final audioB64 = data['delta'] as String?;
          if (audioB64 != null && _onAudioDelta != null) {
            final audioBytes = base64Decode(audioB64);
            _onAudioDelta!(audioBytes);
          }
          break;
          
        case RealtimeConstants.eventTypeResponseAudioTranscriptDelta:
          final transcript = data['delta'] as String?;
          if (transcript != null && _onTranscriptDelta != null) {
            _onTranscriptDelta!(transcript);
          }
          break;
          
        case RealtimeConstants.eventTypeResponseDone:
          _hasActiveResponse = false;
          _onResponseDone?.call();
          break;
          
        case RealtimeConstants.eventTypeInputAudioBufferSpeechStarted:
          _isSpeaking = true;
          _onSpeechStarted?.call();
          // Interrupt AI if there's an active response
          if (_hasActiveResponse) {
            cancelResponse();
          }
          break;
          
        case RealtimeConstants.eventTypeInputAudioBufferSpeechStopped:
          _isSpeaking = false;
          _onSpeechStopped?.call();
          break;
          
        case RealtimeConstants.eventTypeError:
          final error = data['error'] as Map<String, dynamic>?;
          if (error != null) {
            final errorCode = error['code'] as String?;
            // Don't call error callback for expected errors
            if (errorCode != 'response_cancel_not_active' &&
                errorCode != 'conversation_already_has_active_response') {
              _onError?.call(error);
            }
          }
          break;
      }
    } catch (e) {
      _onError?.call({'message': 'Error handling message: $e'});
    }
  }
  
  /// Send audio data to OpenAI
  Future<void> sendAudio(Uint8List audioData) async {
    if (!_connected) {
      throw Exception('Cannot send audio: not connected');
    }
    
    final audioB64 = base64Encode(audioData);
    final event = {
      'type': RealtimeConstants.eventTypeInputAudioBufferAppend,
      'audio': audioB64,
    };
    
    await _sendEvent(event);
  }
  
  /// Commit audio buffer and request response
  Future<void> commitAudio() async {
    if (!_connected) {
      return;
    }
    
    // Commit the audio buffer
    await _sendEvent({
      'type': RealtimeConstants.eventTypeInputAudioBufferCommit,
    });
    
    // Request a response if we don't have one active
    if (!_hasActiveResponse) {
      await _sendEvent({
        'type': RealtimeConstants.eventTypeResponseCreate,
      });
      _hasActiveResponse = true;
    }
  }
  
  /// Cancel the current AI response (for interruption)
  Future<void> cancelResponse() async {
    if (!_connected) {
      return;
    }
    
    // Only cancel if we have an active response
    if (_hasActiveResponse) {
      await _sendEvent({
        'type': RealtimeConstants.eventTypeResponseCancel,
      });
      _hasActiveResponse = false;
    }
    
    // Clear input audio buffer
    await _sendEvent({
      'type': RealtimeConstants.eventTypeInputAudioBufferClear,
    });
  }
  
  /// Send text message to the conversation
  Future<void> sendText(String text) async {
    if (!_connected) {
      throw Exception('Cannot send text: not connected');
    }
    
    final event = {
      'type': RealtimeConstants.eventTypeConversationItemCreate,
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': text,
          },
        ],
      },
    };
    
    await _sendEvent(event);
    
    // Request a response if we don't have one active
    if (!_hasActiveResponse) {
      await _sendEvent({
        'type': RealtimeConstants.eventTypeResponseCreate,
      });
      _hasActiveResponse = true;
    }
  }
  
  // Callback setters
  void setAudioCallback(Function(Uint8List) callback) {
    _onAudioDelta = callback;
  }
  
  void setTranscriptCallback(Function(String) callback) {
    _onTranscriptDelta = callback;
  }
  
  void setResponseDoneCallback(Function() callback) {
    _onResponseDone = callback;
  }
  
  void setSpeechStartedCallback(Function() callback) {
    _onSpeechStarted = callback;
  }
  
  void setSpeechStoppedCallback(Function() callback) {
    _onSpeechStopped = callback;
  }
  
  void setErrorCallback(Function(Map<String, dynamic>) callback) {
    _onError = callback;
  }
}
