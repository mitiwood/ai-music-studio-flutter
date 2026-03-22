import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentTrackId;
  String? _currentTitle;
  String? _currentImageUrl;

  AudioPlayer get player => _player;
  String? get currentTrackId => _currentTrackId;
  String? get currentTitle => _currentTitle;
  String? get currentImageUrl => _currentImageUrl;
  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;

  Future<void> play(String url, {String? trackId, String? title, String? imageUrl}) async {
    _currentTrackId = trackId;
    _currentTitle = title;
    _currentImageUrl = imageUrl;
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> resume() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> stop() async { await _player.stop(); _currentTrackId = null; }
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() => _player.dispose();
}
