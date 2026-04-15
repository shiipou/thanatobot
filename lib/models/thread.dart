class Thread {
  final String id;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Thread({required this.id, required this.createdAt, this.metadata});

  factory Thread.fromJson(Map<String, dynamic> json) => Thread(
    id: json['id'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000),
    metadata: json['metadata'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    'metadata': metadata,
  };
}
