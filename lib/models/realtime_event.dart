import 'dart:convert';

class RealtimeEvent {
  final String type;
  final Map<String, dynamic> data;

  RealtimeEvent({required this.type, required this.data});

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeEvent(type: json['type'] ?? '', data: json);

  Map<String, dynamic> toJson() {
    final map = Map<String, dynamic>.from(data);
    map['type'] = type;
    return map;
  }

  String toJsonString() => jsonEncode(toJson());

  factory RealtimeEvent.inputAudioBufferAppend({required String audioBase64}) =>
      RealtimeEvent(
        type: 'input_audio_buffer.append',
        data: {'type': 'input_audio_buffer.append', 'audio': audioBase64},
      );

  factory RealtimeEvent.inputAudioBufferCommit() => RealtimeEvent(
    type: 'input_audio_buffer.commit',
    data: {'type': 'input_audio_buffer.commit'},
  );

  factory RealtimeEvent.inputAudioBufferClear() => RealtimeEvent(
    type: 'input_audio_buffer.clear',
    data: {'type': 'input_audio_buffer.clear'},
  );

  factory RealtimeEvent.responseCreate() =>
      RealtimeEvent(type: 'response.create', data: {'type': 'response.create'});

  factory RealtimeEvent.responseCancel() =>
      RealtimeEvent(type: 'response.cancel', data: {'type': 'response.cancel'});

  factory RealtimeEvent.conversationItemCreate({required String text}) =>
      RealtimeEvent(
        type: 'conversation.item.create',
        data: {
          'type': 'conversation.item.create',
          'item': {
            'type': 'message',
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': text},
            ],
          },
        },
      );
}
