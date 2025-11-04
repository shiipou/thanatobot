import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'realtime_constants.dart';

/// Service for playing audio from Realtime API
class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  final List<Uint8List> _audioBuffer = [];
  bool _isPlaying = false;
  
  bool get isPlaying => _isPlaying;
  
  /// Add audio chunk to the buffer and play if not already playing
  /// 
  /// Note: This implementation uses BytesSource which may not work properly 
  /// with raw PCM16 audio on all platforms. For production use, consider:
  /// 1. Converting PCM16 to WAV format before playback
  /// 2. Using a platform-specific audio library
  /// 3. Using flutter_sound or just_audio with proper audio format handling
  Future<void> playAudioChunk(Uint8List audioData) async {
    _audioBuffer.add(audioData);
    
    if (!_isPlaying) {
      await _playNextChunk();
    }
  }
  
  /// Play the next chunk from the buffer
  Future<void> _playNextChunk() async {
    if (_audioBuffer.isEmpty) {
      _isPlaying = false;
      return;
    }
    
    _isPlaying = true;
    
    try {
      final chunk = _audioBuffer.removeAt(0);
      
      // Note: audioplayers doesn't directly support raw PCM16 playback
      // You would need to either:
      // 1. Convert PCM16 to a supported format (like WAV) before playing
      // 2. Use a different audio library that supports raw PCM
      // 3. Use platform-specific audio APIs
      
      // For now, we'll use a basic BytesSource which may not work for all platforms
      // In production, you should convert PCM16 to WAV format
      await _player.play(BytesSource(chunk));
      
      // Wait for playback to complete
      await _player.onPlayerComplete.first;
      
      // Play next chunk if available
      await _playNextChunk();
    } catch (e) {
      _isPlaying = false;
      throw Exception('Error playing audio: $e');
    }
  }
  
  /// Stop playback and clear buffer
  Future<void> stop() async {
    _isPlaying = false;
    _audioBuffer.clear();
    await _player.stop();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
