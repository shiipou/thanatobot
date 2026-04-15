enum MessageRole { user, assistant }

class Message {
  final String id;
  final String threadId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool isTranscript;

  Message({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isTranscript = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse content from OpenAI message format
    String content = '';
    if (json['content'] is List) {
      for (var item in json['content']) {
        if (item['type'] == 'text') {
          content += item['text']['value'] ?? '';
        }
      }
    } else if (json['content'] is String) {
      content = json['content'];
    }

    return Message(
      id: json['id'],
      threadId: json['thread_id'] ?? '',
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000),
      isTranscript: json['is_transcript'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'thread_id': threadId,
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
    'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    'is_transcript': isTranscript,
  };

  Message copyWith({
    String? id,
    String? threadId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? isTranscript,
  }) => Message(
    id: id ?? this.id,
    threadId: threadId ?? this.threadId,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    isTranscript: isTranscript ?? this.isTranscript,
  );
}
