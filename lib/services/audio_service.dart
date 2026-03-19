import 'package:just_audio/just_audio.dart';

/// 오디오 재생 서비스 (싱글톤)
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentTrackId;

  AudioPlayer get player => _player;
  String? get currentTrackId => _currentTrackId;
  bool get isPlaying => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;

  Future<void> play(String url, {String? trackId}) async {
    if (_currentTrackId == trackId && _player.playing) {
      await _player.pause();
      return;
    }
    _currentTrackId = trackId;
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async {
    await _player.stop();
    _currentTrackId = null;
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() => _player.dispose();
}
