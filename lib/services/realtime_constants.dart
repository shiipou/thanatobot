/// Constants for OpenAI Realtime API
class RealtimeConstants {
  // API endpoint
  static const String realtimeUrl = 'wss://api.openai.com/v1/realtime';
  
  // Audio configuration
  static const int audioSampleRate = 24000;
  static const String audioFormat = 'pcm16';
  
  // Default settings
  static const String defaultModel = 'gpt-4o-realtime-preview-2024-10-01';
  static const String defaultVoice = 'alloy';
  static const List<String> defaultModalities = ['text', 'audio'];
  static const String defaultInstructions = 'You are a helpful assistant.';
  
  // Available voices
  static const List<String> availableVoices = [
    'alloy',
    'echo',
    'fable',
    'onyx',
    'nova',
    'shimmer',
  ];
  
  // Event types
  static const String eventTypeSessionUpdate = 'session.update';
  static const String eventTypeInputAudioBufferAppend = 'input_audio_buffer.append';
  static const String eventTypeInputAudioBufferCommit = 'input_audio_buffer.commit';
  static const String eventTypeInputAudioBufferClear = 'input_audio_buffer.clear';
  static const String eventTypeConversationItemCreate = 'conversation.item.create';
  static const String eventTypeResponseCreate = 'response.create';
  static const String eventTypeResponseCancel = 'response.cancel';
  
  // Response event types
  static const String eventTypeResponseCreated = 'response.created';
  static const String eventTypeResponseDone = 'response.done';
  static const String eventTypeResponseAudioDelta = 'response.audio.delta';
  static const String eventTypeResponseAudioTranscriptDelta = 'response.audio_transcript.delta';
  static const String eventTypeInputAudioBufferSpeechStarted = 'input_audio_buffer.speech_started';
  static const String eventTypeInputAudioBufferSpeechStopped = 'input_audio_buffer.speech_stopped';
  static const String eventTypeError = 'error';
  
  // VAD (Voice Activity Detection) settings
  static const int vadPrefixPaddingMs = 300;
  static const int vadSilenceDurationMs = 500;
  static const double vadThreshold = 0.5;
}
