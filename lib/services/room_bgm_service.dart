import 'dart:async';
import 'package:flutter/foundation.dart';

class BgmTrack {
  final String id;
  final String title;
  final String artist;
  final Duration duration;

  const BgmTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
  });
}

class RoomBgmService extends ChangeNotifier {
  static final List<BgmTrack> defaultPlaylists = [
    const BgmTrack(
      id: 'bgm_1',
      title: 'Neon Nights (Chill Beats)',
      artist: 'Ab-Play Studio',
      duration: Duration(minutes: 3, seconds: 12),
    ),
    const BgmTrack(
      id: 'bgm_2',
      title: 'Party Groove Lounge',
      artist: 'DJ Pixel',
      duration: Duration(minutes: 2, seconds: 45),
    ),
    const BgmTrack(
      id: 'bgm_3',
      title: 'Lofi Cyber Cafe',
      artist: 'Retro Waves',
      duration: Duration(minutes: 4, seconds: 05),
    ),
  ];

  BgmTrack? _currentTrack;
  bool _isPlaying = false;
  double _volume = 0.5;
  Duration _currentPosition = Duration.zero;
  Timer? _playbackTimer;

  BgmTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  Duration get currentPosition => _currentPosition;

  void playTrack(BgmTrack track) {
    _currentTrack = track;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    _startTimer();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_currentTrack == null && defaultPlaylists.isNotEmpty) {
      playTrack(defaultPlaylists.first);
      return;
    }
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _startTimer();
    } else {
      _playbackTimer?.cancel();
    }
    notifyListeners();
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTrack != null) {
        if (_currentPosition < _currentTrack!.duration) {
          _currentPosition += const Duration(seconds: 1);
          notifyListeners();
        } else {
          _currentPosition = Duration.zero;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
