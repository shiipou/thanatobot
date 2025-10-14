import 'package:flutter_test/flutter_test.dart';
import 'package:thanatobot/models/chat_thread.dart';
import 'package:thanatobot/models/chat_message.dart';

void main() {
  group('ChatThread', () {
    test('should create a thread from JSON', () {
      final json = {
        'id': 'thread_123',
        'title': 'Test Thread',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'lastMessageAt': '2025-01-01T00:00:00.000Z',
      };

      final thread = ChatThread.fromJson(json);

      expect(thread.id, 'thread_123');
      expect(thread.title, 'Test Thread');
      expect(thread.createdAt.year, 2025);
      expect(thread.lastMessageAt.year, 2025);
    });

    test('should convert thread to JSON', () {
      final thread = ChatThread(
        id: 'thread_123',
        title: 'Test Thread',
        createdAt: DateTime(2025, 1, 1),
        lastMessageAt: DateTime(2025, 1, 1),
      );

      final json = thread.toJson();

      expect(json['id'], 'thread_123');
      expect(json['title'], 'Test Thread');
      expect(json['createdAt'], isA<String>());
      expect(json['lastMessageAt'], isA<String>());
    });
  });

  group('ChatMessage', () {
    test('should create a message from JSON', () {
      final json = {
        'id': 'msg_123',
        'threadId': 'thread_123',
        'content': 'Test message',
        'isUser': true,
        'timestamp': '2025-01-01T00:00:00.000Z',
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 'msg_123');
      expect(message.threadId, 'thread_123');
      expect(message.content, 'Test message');
      expect(message.isUser, true);
      expect(message.timestamp.year, 2025);
    });

    test('should convert message to JSON', () {
      final message = ChatMessage(
        id: 'msg_123',
        threadId: 'thread_123',
        content: 'Test message',
        isUser: true,
        timestamp: DateTime(2025, 1, 1),
      );

      final json = message.toJson();

      expect(json['id'], 'msg_123');
      expect(json['threadId'], 'thread_123');
      expect(json['content'], 'Test message');
      expect(json['isUser'], true);
      expect(json['timestamp'], isA<String>());
    });
  });
}
