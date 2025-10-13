import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;
  final String assistantId;
  static const String baseUrl = 'https://api.openai.com/v1';

  OpenAIService({
    required this.apiKey,
    required this.assistantId,
  });

  Future<String> createThread() async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    } else {
      throw Exception('Failed to create thread: ${response.body}');
    }
  }

  Future<void> addMessage(String threadId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads/$threadId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        'role': 'user',
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add message: ${response.body}');
    }
  }

  Future<String> runAssistant(String threadId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads/$threadId/runs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        'assistant_id': assistantId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    } else {
      throw Exception('Failed to run assistant: ${response.body}');
    }
  }

  Future<String> getRunStatus(String threadId, String runId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/threads/$threadId/runs/$runId'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] as String;
    } else {
      throw Exception('Failed to get run status: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String threadId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/threads/$threadId/messages'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to get messages: ${response.body}');
    }
  }

  Future<String> sendMessageAndGetResponse(String threadId, String content) async {
    // Add user message
    await addMessage(threadId, content);

    // Run the assistant
    final runId = await runAssistant(threadId);

    // Wait for completion
    String status = 'queued';
    while (status == 'queued' || status == 'in_progress') {
      await Future.delayed(const Duration(seconds: 1));
      status = await getRunStatus(threadId, runId);
    }

    if (status == 'completed') {
      // Get the latest messages
      final messages = await getMessages(threadId);
      if (messages.isNotEmpty) {
        final latestMessage = messages[0];
        final content = latestMessage['content'] as List;
        if (content.isNotEmpty) {
          final text = content[0]['text'];
          return text['value'] as String;
        }
      }
    }

    throw Exception('Failed to get response from assistant');
  }
}
