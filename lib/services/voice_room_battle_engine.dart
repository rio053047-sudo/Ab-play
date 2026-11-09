import 'dart:async';
import 'package:flutter/foundation.dart';

enum RoomBattleStatus {
  idle,
  invited,
  active,
  finished,
}

class VoiceRoomBattleEngine extends ChangeNotifier {
  RoomBattleStatus _status = RoomBattleStatus.idle;
  String _invitingRoomId = '';
  String _rivalRoomTitle = '';

  int _teamScore = 0;
  int _rivalScore = 0;
  int _remainingSeconds = 180; // 3 minutes standard battle
  Timer? _battleTimer;
  String? _winnerTitle;

  RoomBattleStatus get status => _status;
  int get teamScore => _teamScore;
  int get rivalScore => _rivalScore;
  int get remainingSeconds => _remainingSeconds;
  String get rivalRoomTitle => _rivalRoomTitle;
  String? get winnerTitle => _winnerTitle;

  void startBattleInvite({required String rivalTitle, required String rivalId}) {
    _status = RoomBattleStatus.invited;
    _rivalRoomTitle = rivalTitle;
    _invitingRoomId = rivalId;
    notifyListeners();
  }

  void acceptBattle() {
    _status = RoomBattleStatus.active;
    _teamScore = 0;
    _rivalScore = 0;
    _remainingSeconds = 180;
    _winnerTitle = null;

    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        // Server simulated rival room activity with anti-spam caps
        if (_remainingSeconds % 5 == 0) {
          _rivalScore += 50;
        }
        notifyListeners();
      } else {
        _finishBattle();
      }
    });
    notifyListeners();
  }

  void rejectBattle() {
    _status = RoomBattleStatus.idle;
    notifyListeners();
  }

  // Server-authoritative gift points contribution
  void addBattleGiftPoints(int points) {
    if (_status != RoomBattleStatus.active) return;
    _teamScore += points;
    notifyListeners();
  }

  void _finishBattle() {
    _battleTimer?.cancel();
    _status = RoomBattleStatus.finished;
    if (_teamScore > _rivalScore) {
      _winnerTitle = 'VICTORY! Our Room Won! 🏆';
    } else if (_teamScore < _rivalScore) {
      _winnerTitle = 'DEFEAT! Rival Room Won! ⚔️';
    } else {
      _winnerTitle = 'DRAW! It is a Tie! 🤝';
    }
    notifyListeners();
  }

  void reset() {
    _battleTimer?.cancel();
    _status = RoomBattleStatus.idle;
    _teamScore = 0;
    _rivalScore = 0;
    _remainingSeconds = 180;
    _winnerTitle = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    super.dispose();
  }
}
