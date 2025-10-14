import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
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

  Future<String> runAssistantWithStream(String threadId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads/$threadId/runs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        'assistant_id': assistantId,
        'stream': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    } else {
      throw Exception('Failed to run assistant: ${response.body}');
    }
  }

  Stream<String> streamAssistantRun(String threadId) async* {
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/threads/$threadId/runs'),
    );
    
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'OpenAI-Beta': 'assistants=v2',
      'Accept': 'text/event-stream',
    });
    
    request.body = jsonEncode({
      'assistant_id': assistantId,
      'stream': true,
    });

    final client = http.Client();
    try {
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Failed to start streaming: $errorBody');
      }

      String buffer = '';
      String accumulatedText = '';
      
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        // Process complete lines
        while (buffer.contains('\n')) {
          final lineEndIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEndIndex).trim();
          buffer = buffer.substring(lineEndIndex + 1);
          
          if (line.startsWith('data: ')) {
            final data = line.substring(6); // Remove 'data: ' prefix
            
            if (data == '[DONE]') {
              return;
            }
            
            try {
              final eventData = jsonDecode(data);
              
              // Handle message delta events
              if (eventData['object'] == 'thread.message.delta') {
                final delta = eventData['delta'];
                if (delta != null && delta['content'] != null) {
                  final content = delta['content'];
                  if (content is List && content.isNotEmpty) {
                    for (final contentItem in content) {
                      if (contentItem['type'] == 'text' && contentItem['text'] != null) {
                        final textDelta = contentItem['text'];
                        if (textDelta['value'] != null) {
                          final deltaText = textDelta['value'] as String;
                          accumulatedText += deltaText;
                          yield deltaText;
                        }
                      }
                    }
                  }
                }
              }
              // Handle run step delta events (for function calls, etc.)
              else if (eventData['object'] == 'thread.run.step.delta') {
                final delta = eventData['delta'];
                if (delta != null && delta['step_details'] != null) {
                  final stepDetails = delta['step_details'];
                  if (stepDetails['type'] == 'message_creation') {
                    // Message creation steps don't contain text deltas
                    continue;
                  }
                }
              }
            } catch (e) {
              // Skip malformed JSON events
              continue;
            }
          }
        }
      }
    } finally {
      client.close();
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

  Stream<String> sendMessageAndGetStreamResponse(String threadId, String content) async* {
    try {
      // Add user message
      await addMessage(threadId, content);

      // Stream the assistant run response
      await for (final chunk in streamAssistantRun(threadId)) {
        yield chunk;
      }
    } catch (e) {
      throw Exception('Failed to get streaming response: $e');
    }
  }
}
