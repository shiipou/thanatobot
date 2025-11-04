import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'realtime_constants.dart';

/// Service for recording audio for Realtime API
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  bool _isRecording = false;
  
  Function(Uint8List)? _onAudioData;
  
  bool get isRecording => _isRecording;
  
  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  /// Start recording audio
  Future<void> startRecording(Function(Uint8List) onAudioData) async {
    if (_isRecording) {
      return;
    }
    
    // Check and request permission if needed
    if (!await checkPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception('Microphone permission not granted');
      }
    }
    
    _onAudioData = onAudioData;
    
    try {
      // Check if the recorder has permission
      if (await _recorder.hasPermission()) {
        // Start recording with PCM16 format at 24kHz
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: RealtimeConstants.audioSampleRate,
            numChannels: 1,
          ),
        );
        
        _isRecording = true;
        
        // Listen to the audio stream
        _audioStreamSubscription = stream.listen(
          (data) {
            if (_isRecording && _onAudioData != null) {
              _onAudioData!(data);
            }
          },
          onError: (error) {
            _isRecording = false;
            throw Exception('Error recording audio: $error');
          },
          onDone: () {
            _isRecording = false;
          },
        );
      } else {
        throw Exception('Microphone permission not available');
      }
    } catch (e) {
      _isRecording = false;
      rethrow;
    }
  }
  
  /// Stop recording audio
  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }
    
    _isRecording = false;
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    await _recorder.stop();
    _onAudioData = null;
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await stopRecording();
    _recorder.dispose();
  }
}
