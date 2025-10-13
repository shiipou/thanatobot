class ChatThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
    };
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
    );
  }
}
