import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/thread.dart';
import '../models/message.dart';
import '../models/realtime_event.dart';

class OpenAIService {
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String realtimeUrl = 'wss://api.openai.com/v1/realtime';

  final String apiKey;
  final String assistantId;

  WebSocketChannel? _realtimeChannel;
  StreamController<RealtimeEvent>? _realtimeEventsController;
  bool _isConnected = false;

  OpenAIService({required this.apiKey, required this.assistantId});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'OpenAI-Beta': 'assistants=v2',
  };

  // Thread Management
  Future<Thread> createThread() async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Thread.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create thread: ${response.body}');
    }
  }

  Future<List<Thread>> listThreads() async {
    // Note: OpenAI doesn't provide a direct list threads API
    // You'll need to store thread IDs locally
    // This is a placeholder that would need local storage implementation
    throw UnimplementedError('Thread listing requires local storage');
  }

  Future<Thread> retrieveThread(String threadId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/threads/$threadId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Thread.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to retrieve thread: ${response.body}');
    }
  }

  // Assistant Management
  Future<Map<String, dynamic>> getAssistant() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistants/$assistantId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get assistant: ${response.body}');
    }
  }

  // Message Management
  Future<Message> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads/$threadId/messages'),
      headers: _headers,
      body: jsonEncode({'role': 'user', 'content': content}),
    );

    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<Message>> listMessages(String threadId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/threads/$threadId/messages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = (data['data'] as List)
          .map((msg) => Message.fromJson(msg))
          .toList();
      // Reverse to show oldest first
      return messages.reversed.toList();
    } else {
      throw Exception('Failed to list messages: ${response.body}');
    }
  }

  // Run Assistant
  Future<void> runAssistant({
    required String threadId,
    String? instructions,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads/$threadId/runs'),
      headers: _headers,
      body: jsonEncode({
        'assistant_id': assistantId,
        if (instructions != null) 'instructions': instructions,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to run assistant: ${response.body}');
    }

    final runId = jsonDecode(response.body)['id'];

    // Poll for completion
    await _waitForRunCompletion(threadId, runId);
  }

  Future<void> _waitForRunCompletion(String threadId, String runId) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));

      final response = await http.get(
        Uri.parse('$baseUrl/threads/$threadId/runs/$runId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final status = jsonDecode(response.body)['status'];
        if (status == 'completed') {
          return;
        } else if (status == 'failed' ||
            status == 'cancelled' ||
            status == 'expired') {
          throw Exception('Run failed with status: $status');
        }
      } else {
        throw Exception('Failed to check run status: ${response.body}');
      }
    }
  }

  // Realtime API
  Future<void> connectRealtime({
    String model = 'gpt-realtime',
    String voice = 'alloy',
    String? instructions,
    List<Map<String, dynamic>>? tools,
  }) async {
    if (_isConnected) {
      return;
    }

    try {
      final uri = Uri.parse('$realtimeUrl?model=$model');

      // Connect with proper authentication headers (no OpenAI-Beta needed)
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      _realtimeChannel = IOWebSocketChannel(socket);

      // Configure session exactly like Python implementation
      _realtimeChannel!.sink.add(
        jsonEncode({
          'type': 'session.update',
          'session': {
            'type': 'realtime',
            'model': model,
            'output_modalities': ['audio'],
            'audio': {
              'input': {
                'format': {'type': 'audio/pcm', 'rate': 24000},
                'turn_detection': {'type': 'semantic_vad'},
              },
              'output': {
                'format': {'type': 'audio/pcm', 'rate': 24000},
                'voice': voice,
              },
            },
            if (instructions != null) 'instructions': instructions,
            if (tools != null) 'tools': tools,
          },
        }),
      );

      _realtimeEventsController = StreamController<RealtimeEvent>.broadcast();
      _isConnected = true;

      _realtimeChannel!.stream.listen(
        (data) {
          final event = RealtimeEvent.fromJson(jsonDecode(data));
          _realtimeEventsController?.add(event);
        },
        onError: (error) {
          _isConnected = false;
          _realtimeEventsController?.addError(error);
        },
        onDone: () {
          _isConnected = false;
          _realtimeEventsController?.close();
        },
      );
    } catch (e) {
      _isConnected = false;
      throw Exception('Failed to connect to realtime API: $e');
    }
  }

  void disconnectRealtime() {
    _realtimeChannel?.sink.close();
    _realtimeEventsController?.close();
    _realtimeChannel = null;
    _realtimeEventsController = null;
    _isConnected = false;
  }

  Stream<RealtimeEvent>? get realtimeEvents =>
      _realtimeEventsController?.stream;

  bool get isRealtimeConnected => _isConnected;

  void sendRealtimeEvent(RealtimeEvent event) {
    if (_isConnected && _realtimeChannel != null) {
      _realtimeChannel!.sink.add(event.toJsonString());
    }
  }

  void sendAudio(Uint8List audioData) {
    final audioBase64 = base64Encode(audioData);
    sendRealtimeEvent(
      RealtimeEvent.inputAudioBufferAppend(audioBase64: audioBase64),
    );
  }

  void commitAudio() {
    sendRealtimeEvent(RealtimeEvent.inputAudioBufferCommit());
    sendRealtimeEvent(RealtimeEvent.responseCreate());
  }

  void clearAudioBuffer() {
    sendRealtimeEvent(RealtimeEvent.inputAudioBufferClear());
  }

  void cancelResponse() {
    sendRealtimeEvent(RealtimeEvent.responseCancel());
  }

  // Send function call output back to the model
  void sendFunctionCallOutput({
    required String callId,
    required String output,
  }) {
    if (_isConnected && _realtimeChannel != null) {
      _realtimeChannel!.sink.add(
        jsonEncode({
          'type': 'conversation.item.create',
          'item': {
            'type': 'function_call_output',
            'call_id': callId,
            'output': output,
          },
        }),
      );
      // Trigger response generation
      sendRealtimeEvent(RealtimeEvent.responseCreate());
    }
  }

  // Search knowledge base using the assistant's file_search
  Future<String> searchKnowledgeBase(
    String vectorDatabaseId,
    String query,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vector_stores/$vectorDatabaseId/search'),
        headers: _headers,
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final status = jsonDecode(response.body)['status'];
        if (status == 'completed') {
          return jsonDecode(response.body)['data'].toString();
        } else if (status == 'failed' ||
            status == 'cancelled' ||
            status == 'expired') {
          return 'Search failed with status: $status';
        }
      } else {
        return 'Failed to check run status: \nError ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'I encountered an error while searching: ${e.toString()}';
    }
    return 'Search did not complete successfully. This must not happen.';
  }

  void dispose() {
    disconnectRealtime();
  }
}
