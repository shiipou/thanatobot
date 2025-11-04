import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_thread.dart';
import '../models/chat_message.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Thread operations
  Future<List<ChatThread>> getThreads() async {
    final threadsJson = _prefs?.getString('threads') ?? '[]';
    final List<dynamic> threadsList = jsonDecode(threadsJson);
    return threadsList.map((json) => ChatThread.fromJson(json)).toList();
  }

  Future<void> saveThread(ChatThread thread) async {
    final threads = await getThreads();
    final index = threads.indexWhere((t) => t.id == thread.id);
    
    if (index >= 0) {
      threads[index] = thread;
    } else {
      threads.add(thread);
    }
    
    final threadsJson = jsonEncode(threads.map((t) => t.toJson()).toList());
    await _prefs?.setString('threads', threadsJson);
  }

  Future<void> deleteThread(String threadId) async {
    final threads = await getThreads();
    threads.removeWhere((t) => t.id == threadId);
    
    final threadsJson = jsonEncode(threads.map((t) => t.toJson()).toList());
    await _prefs?.setString('threads', threadsJson);
    
    // Also delete messages for this thread
    await _prefs?.remove('messages_$threadId');
  }

  // Message operations
  Future<List<ChatMessage>> getMessages(String threadId) async {
    final messagesJson = _prefs?.getString('messages_$threadId') ?? '[]';
    final List<dynamic> messagesList = jsonDecode(messagesJson);
    return messagesList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final messages = await getMessages(message.threadId);
    messages.add(message);
    
    final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs?.setString('messages_${message.threadId}', messagesJson);
  }

  // OpenAI API Key
  Future<String?> getApiKey() async {
    return _prefs?.getString('openai_api_key');
  }

  Future<void> saveApiKey(String apiKey) async {
    await _prefs?.setString('openai_api_key', apiKey);
  }

  // Assistant ID
  Future<String?> getAssistantId() async {
    return _prefs?.getString('assistant_id');
  }

  Future<void> saveAssistantId(String assistantId) async {
    await _prefs?.setString('assistant_id', assistantId);
  }

  // Realtime API settings
  Future<bool> getUseRealtimeApi() async {
    return _prefs?.getBool('use_realtime_api') ?? false;
  }

  Future<void> saveUseRealtimeApi(bool useRealtime) async {
    await _prefs?.setBool('use_realtime_api', useRealtime);
  }

  Future<String> getRealtimeModel() async {
    return _prefs?.getString('realtime_model') ?? 'gpt-4o-realtime-preview-2024-10-01';
  }

  Future<void> saveRealtimeModel(String model) async {
    await _prefs?.setString('realtime_model', model);
  }

  Future<String> getRealtimeVoice() async {
    return _prefs?.getString('realtime_voice') ?? 'alloy';
  }

  Future<void> saveRealtimeVoice(String voice) async {
    await _prefs?.setString('realtime_voice', voice);
  }

  Future<String> getCommunicationMode() async {
    return _prefs?.getString('communication_mode') ?? 'text';
  }

  Future<void> saveCommunicationMode(String mode) async {
    await _prefs?.setString('communication_mode', mode);
  }
}
