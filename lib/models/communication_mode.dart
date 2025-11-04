/// Communication mode for the chatbot
enum CommunicationMode {
  text,
  voice,
  both,
}

extension CommunicationModeExtension on CommunicationMode {
  String get name {
    switch (this) {
      case CommunicationMode.text:
        return 'Text';
      case CommunicationMode.voice:
        return 'Voice';
      case CommunicationMode.both:
        return 'Text & Voice';
    }
  }
  
  bool get supportsText {
    return this == CommunicationMode.text || this == CommunicationMode.both;
  }
  
  bool get supportsVoice {
    return this == CommunicationMode.voice || this == CommunicationMode.both;
  }
  
  static CommunicationMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'voice':
        return CommunicationMode.voice;
      case 'both':
        return CommunicationMode.both;
      case 'text':
      default:
        return CommunicationMode.text;
    }
  }
}
