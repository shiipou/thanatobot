class AppSettings {
  final String apiKey;
  final String assistantId;
  final String voice;

  AppSettings({
    required this.apiKey,
    required this.assistantId,
    this.voice = 'alloy',
  });

  bool get isConfigured => apiKey.isNotEmpty && assistantId.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'assistantId': assistantId,
    'voice': voice,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    apiKey: json['apiKey'] ?? '',
    assistantId: json['assistantId'] ?? '',
    voice: json['voice'] ?? 'alloy',
  );

  factory AppSettings.empty() => AppSettings(apiKey: '', assistantId: '');

  AppSettings copyWith({String? apiKey, String? assistantId, String? voice}) =>
      AppSettings(
        apiKey: apiKey ?? this.apiKey,
        assistantId: assistantId ?? this.assistantId,
        voice: voice ?? this.voice,
      );
}
