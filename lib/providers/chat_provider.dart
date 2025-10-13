import 'package:flutter/foundation.dart';
import '../models/chat_thread.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/openai_service.dart';

class ChatProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<ChatThread> _threads = [];
  Map<String, List<ChatMessage>> _messages = {};
  OpenAIService? _openAIService;
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._storageService) {
    _init();
  }

  List<ChatThread> get threads => _threads;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => _openAIService != null;

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

    if (apiKey != null && assistantId != null) {
      _openAIService = OpenAIService(
        apiKey: apiKey,
        assistantId: assistantId,
      );
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
    if (_openAIService == null) {
      throw Exception('OpenAI service not configured');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final openAIThreadId = await _openAIService!.createThread();
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

  Future<void> deleteThread(String threadId) async {
    await _storageService.deleteThread(threadId);
    _threads.removeWhere((t) => t.id == threadId);
    _messages.remove(threadId);
    notifyListeners();
  }
}
