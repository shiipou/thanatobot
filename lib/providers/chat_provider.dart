import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/chat_thread.dart';
import '../models/chat_message.dart';
import '../models/communication_mode.dart';
import '../services/storage_service.dart';
import '../services/openai_service.dart';
import '../services/openai_realtime_client.dart';
import '../services/audio_recording_service.dart';
import '../services/audio_playback_service.dart';

class ChatProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<ChatThread> _threads = [];
  Map<String, List<ChatMessage>> _messages = {};
  OpenAIService? _openAIService;
  OpenAIRealtimeClient? _realtimeService;
  AudioRecordingService? _recordingService;
  AudioPlaybackService? _playbackService;
  bool _isLoading = false;
  String? _error;
  bool _useRealtimeApi = false;
  CommunicationMode _communicationMode = CommunicationMode.text;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  String _currentTranscript = '';

  ChatProvider(this._storageService) {
    _init();
  }

  List<ChatThread> get threads => _threads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => _openAIService != null || _realtimeService != null;
  bool get useRealtimeApi => _useRealtimeApi;
  CommunicationMode get communicationMode => _communicationMode;
  bool get isRecording => _isRecording;
  bool get isPlayingAudio => _isPlayingAudio;
  String get currentTranscript => _currentTranscript;

  List<ChatMessage> getMessages(String threadId) {
    return _messages[threadId] ?? [];
  }

  Future<void> _init() async {
    await _loadThreads();
    await _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final apiKey = await _storageService.getApiKey();
    final assistantId = await _storageService.getAssistantId();
    _useRealtimeApi = await _storageService.getUseRealtimeApi();
    final modeString = await _storageService.getCommunicationMode();
    _communicationMode = CommunicationModeExtension.fromString(modeString);

    if (apiKey != null) {
      if (_useRealtimeApi) {
        // Initialize Realtime API services
        final model = await _storageService.getRealtimeModel();
        final voice = await _storageService.getRealtimeVoice();
        
        _realtimeService = OpenAIRealtimeClient(
          apiKey: apiKey,
          model: model,
          voice: voice,
        );
        
        _recordingService = AudioRecordingService();
        _playbackService = AudioPlaybackService();
        
        // Set up callbacks
        _realtimeService!.setAudioCallback(_handleAudioDelta);
        _realtimeService!.setTranscriptCallback(_handleTranscriptDelta);
        _realtimeService!.setResponseDoneCallback(_handleResponseDone);
        _realtimeService!.setSpeechStartedCallback(_handleSpeechStarted);
        _realtimeService!.setSpeechStoppedCallback(_handleSpeechStopped);
        _realtimeService!.setErrorCallback(_handleRealtimeError);
      } else if (assistantId != null) {
        // Initialize traditional Assistant API
        _openAIService = OpenAIService(
          apiKey: apiKey,
          assistantId: assistantId,
        );
      }
      notifyListeners();
    }
  }

  Future<void> configure(String apiKey, String assistantId) async {
    await _storageService.saveApiKey(apiKey);
    await _storageService.saveAssistantId(assistantId);
    _openAIService = OpenAIService(
      apiKey: apiKey,
      assistantId: assistantId,
    );
    _error = null;
    notifyListeners();
  }

  Future<void> configureRealtime({
    required String apiKey,
    required bool useRealtime,
    String? model,
    String? voice,
    CommunicationMode? mode,
  }) async {
    await _storageService.saveApiKey(apiKey);
    await _storageService.saveUseRealtimeApi(useRealtime);
    
    if (model != null) {
      await _storageService.saveRealtimeModel(model);
    }
    if (voice != null) {
      await _storageService.saveRealtimeVoice(voice);
    }
    if (mode != null) {
      await _storageService.saveCommunicationMode(mode.toString().split('.').last);
      _communicationMode = mode;
    }
    
    _useRealtimeApi = useRealtime;
    
    // Disconnect any existing services
    await _disconnectRealtimeServices();
    
    // Reinitialize
    await _loadConfiguration();
    
    _error = null;
    notifyListeners();
  }

  Future<void> _disconnectRealtimeServices() async {
    await _realtimeService?.disconnect();
    await _recordingService?.dispose();
    await _playbackService?.dispose();
    _realtimeService = null;
    _recordingService = null;
    _playbackService = null;
  }

  // Realtime API callbacks
  void _handleAudioDelta(Uint8List audioData) {
    _playbackService?.playAudioChunk(audioData);
    _isPlayingAudio = true;
    notifyListeners();
  }

  void _handleTranscriptDelta(String transcript) {
    _currentTranscript += transcript;
    notifyListeners();
  }

  void _handleResponseDone() {
    // Save the complete transcript as a message if we have one
    if (_currentTranscript.isNotEmpty) {
      // Find the current thread and save the message
      // This would need to be tracked separately
      _currentTranscript = '';
    }
    _isPlayingAudio = false;
    notifyListeners();
  }

  void _handleSpeechStarted() {
    notifyListeners();
  }

  void _handleSpeechStopped() {
    notifyListeners();
  }

  void _handleRealtimeError(Map<String, dynamic> error) {
    _error = error['message']?.toString() ?? 'Unknown error';
    notifyListeners();
  }

  Future<void> _loadThreads() async {
    _threads = await _storageService.getThreads();
    _threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    notifyListeners();
  }

  Future<void> loadMessages(String threadId) async {
    _messages[threadId] = await _storageService.getMessages(threadId);
    notifyListeners();
  }

  Future<ChatThread> createThread(String title) async {
    if (!isConfigured) {
      throw Exception('Service not configured');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? openAIThreadId;
      
      // Only create a thread in OpenAI if using Assistant API
      if (!_useRealtimeApi && _openAIService != null) {
        openAIThreadId = await _openAIService!.createThread();
      } else {
        // For Realtime API, we'll use a local ID
        openAIThreadId = 'realtime_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      final now = DateTime.now();
      
      final thread = ChatThread(
        id: openAIThreadId,
        title: title,
        createdAt: now,
        lastMessageAt: now,
      );

      await _storageService.saveThread(thread);
      _threads.insert(0, thread);
      _messages[thread.id] = [];

      return thread;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String threadId, String content) async {
    if (_useRealtimeApi && _realtimeService != null) {
      // Use Realtime API for text
      await _sendMessageRealtime(threadId, content);
    } else if (_openAIService != null) {
      // Use traditional Assistant API
      await _sendMessageAssistant(threadId, content);
    } else {
      throw Exception('No service configured');
    }
  }

  Future<void> _sendMessageAssistant(String threadId, String content) async {
    if (_openAIService == null) {
      throw Exception('OpenAI service not configured');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Save user message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        threadId: threadId,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );

      await _storageService.saveMessage(userMessage);
      _messages[threadId] = await _storageService.getMessages(threadId);

      // Update thread last message time
      final threadIndex = _threads.indexWhere((t) => t.id == threadId);
      if (threadIndex >= 0) {
        final thread = _threads[threadIndex];
        final updatedThread = ChatThread(
          id: thread.id,
          title: thread.title,
          createdAt: thread.createdAt,
          lastMessageAt: DateTime.now(),
        );
        await _storageService.saveThread(updatedThread);
        _threads[threadIndex] = updatedThread;
        _threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }

      notifyListeners();

      // Create a placeholder assistant message that will be updated with streaming content
      final assistantMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      final assistantMessage = ChatMessage(
        id: assistantMessageId,
        threadId: threadId,
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Add the placeholder message to the list
      if (_messages[threadId] == null) {
        _messages[threadId] = [];
      }
      _messages[threadId]!.add(assistantMessage);
      notifyListeners();

      // Stream the response from OpenAI
      String fullResponse = '';
      await for (final chunk in _openAIService!.sendMessageAndGetStreamResponse(threadId, content)) {
        fullResponse += chunk;
        
        // Update the assistant message content
        final messageIndex = _messages[threadId]!.indexWhere((m) => m.id == assistantMessageId);
        if (messageIndex >= 0) {
          _messages[threadId]![messageIndex] = ChatMessage(
            id: assistantMessageId,
            threadId: threadId,
            content: fullResponse,
            isUser: false,
            timestamp: assistantMessage.timestamp,
          );
          notifyListeners();
        }
      }

      // Save the final complete message
      final finalMessage = ChatMessage(
        id: assistantMessageId,
        threadId: threadId,
        content: fullResponse,
        isUser: false,
        timestamp: assistantMessage.timestamp,
      );
      
      await _storageService.saveMessage(finalMessage);

      // Update thread last message time again
      if (threadIndex >= 0) {
        final thread = _threads[threadIndex];
        final updatedThread = ChatThread(
          id: thread.id,
          title: thread.title,
          createdAt: thread.createdAt,
          lastMessageAt: DateTime.now(),
        );
        await _storageService.saveThread(updatedThread);
        _threads[threadIndex] = updatedThread;
        _threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendMessageRealtime(String threadId, String content) async {
    if (_realtimeService == null) {
      throw Exception('Realtime service not configured');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure connected
      if (!_realtimeService!.isConnected) {
        await _realtimeService!.connect();
      }

      // Save user message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        threadId: threadId,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );

      await _storageService.saveMessage(userMessage);
      _messages[threadId] = await _storageService.getMessages(threadId);

      // Update thread last message time
      final threadIndex = _threads.indexWhere((t) => t.id == threadId);
      if (threadIndex >= 0) {
        final thread = _threads[threadIndex];
        final updatedThread = ChatThread(
          id: thread.id,
          title: thread.title,
          createdAt: thread.createdAt,
          lastMessageAt: DateTime.now(),
        );
        await _storageService.saveThread(updatedThread);
        _threads[threadIndex] = updatedThread;
        _threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }

      notifyListeners();

      // Send text to realtime API
      await _realtimeService!.sendText(content);

      // The response will come through callbacks
      // For now, we'll wait a bit and then save what we received
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentTranscript.isNotEmpty) {
        final assistantMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          threadId: threadId,
          content: _currentTranscript,
          isUser: false,
          timestamp: DateTime.now(),
        );

        await _storageService.saveMessage(assistantMessage);
        _messages[threadId] = await _storageService.getMessages(threadId);
        _currentTranscript = '';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Voice recording methods
  Future<void> startVoiceRecording() async {
    if (_recordingService == null || _realtimeService == null) {
      throw Exception('Realtime services not configured');
    }

    try {
      // Ensure connected to realtime API
      if (!_realtimeService!.isConnected) {
        await _realtimeService!.connect();
      }

      _isRecording = true;
      notifyListeners();

      // Start recording and stream audio to realtime API
      await _recordingService!.startRecording((audioData) async {
        if (_realtimeService != null && _realtimeService!.isConnected) {
          await _realtimeService!.sendAudio(audioData);
        }
      });
    } catch (e) {
      _isRecording = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopVoiceRecording() async {
    if (_recordingService == null || _realtimeService == null) {
      return;
    }

    try {
      _isRecording = false;
      await _recordingService!.stopRecording();
      
      // Commit the audio buffer to get a response
      if (_realtimeService!.isConnected) {
        await _realtimeService!.commitAudio();
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelVoiceRecording() async {
    if (_recordingService == null || _realtimeService == null) {
      return;
    }

    try {
      _isRecording = false;
      await _recordingService!.stopRecording();
      
      // Cancel any active response
      if (_realtimeService!.isConnected) {
        await _realtimeService!.cancelResponse();
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteThread(String threadId) async {
    await _storageService.deleteThread(threadId);
    _threads.removeWhere((t) => t.id == threadId);
    _messages.remove(threadId);
    notifyListeners();
  }
}
