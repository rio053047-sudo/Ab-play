import 'dart:async';
import 'package:flutter/material.dart';
import '../models/voice_room.dart';
import '../services/audio_rtc_service.dart';
import '../services/room_bgm_service.dart';

class VoiceRoomViewModel extends ChangeNotifier {
  final AudioRtcService _rtcService;
  final RoomBgmService _bgmService;

  VoiceRoomModel? _activeRoom;
  String _currentUserId = '8842109';
  String _currentUserName = 'AbPlay_Gamer';

  final List<VoiceRoomMessage> _messages = [];
  bool _isMicMuted = true;
  bool _isSpeakerMuted = false;
  RoomGift? _lastSentGift;
  int _lastSentGiftCombo = 1;
  Timer? _giftAnimationTimer;

  static const List<RoomGift> standardGifts = [
    RoomGift(id: 'rose', name: 'Rose', coinCost: 10, icon: '🌹', effectName: 'Rose Petal Rain'),
    RoomGift(id: 'coffee', name: 'Coffee', coinCost: 20, icon: '☕', effectName: 'Warm Steam'),
    RoomGift(id: 'heart', name: 'Love Heart', coinCost: 50, icon: '💖', effectName: 'Heart Burst'),
    RoomGift(id: 'party_popper', name: 'Popper', coinCost: 100, icon: '🎉', effectName: 'Confetti Wave'),
    RoomGift(id: 'sports_car', name: 'Supercar', coinCost: 500, icon: '🏎️', effectName: 'Engine Roar'),
    RoomGift(id: 'diamond_ring', name: 'Ring', coinCost: 1000, icon: '💍', effectName: 'Diamond Sparkle'),
    RoomGift(id: 'rocket', name: 'Rocket', coinCost: 2000, icon: '🚀', effectName: 'Space Launch'),
    RoomGift(id: 'castle', name: 'Magic Castle', coinCost: 5000, icon: '🏰', effectName: 'Royal Fireworks'),
  ];

  VoiceRoomViewModel({
    AudioRtcService? rtcService,
    RoomBgmService? bgmService,
  })  : _rtcService = rtcService ?? RealAudioRtcService(),
        _bgmService = bgmService ?? RoomBgmService();

  VoiceRoomModel? get activeRoom => _activeRoom;
  List<VoiceRoomMessage> get messages => List.unmodifiable(_messages);
  bool get isMicMuted => _isMicMuted;
  bool get isSpeakerMuted => _isSpeakerMuted;
  AudioRtcService get rtcService => _rtcService;
  RoomBgmService get bgmService => _bgmService;
  RoomGift? get lastSentGift => _lastSentGift;
  int get lastSentGiftCombo => _lastSentGiftCombo;
  String get currentUserId => _currentUserId;

  void setLoggedInUser(String uid, String name) {
    _currentUserId = uid;
    _currentUserName = name;
  }

  Future<void> enterRoom(VoiceRoomModel room) async {
    _activeRoom = room;
    _messages.clear();
    _messages.add(
      VoiceRoomMessage(
        id: 'msg_welcome',
        senderId: 'system',
        senderName: 'Ab-Play System',
        text: 'Welcome to "${room.title}"! Enjoy the party and follow community rules.',
        isSystem: true,
      ),
    );

    await _rtcService.joinChannel(
      roomId: room.id,
      userId: _currentUserId,
      isSpeaker: room.hostId == _currentUserId,
    );

    _isMicMuted = room.hostId != _currentUserId;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    if (_activeRoom != null) {
      final mySeat = _activeRoom!.seats.firstWhere(
        (s) => s.userId == _currentUserId,
        orElse: () => VoiceRoomSeat(index: -1),
      );
      if (mySeat.index != -1) {
        mySeat.leave();
      }
    }
    await _rtcService.leaveChannel();
    _bgmService.stop();
    _activeRoom = null;
    notifyListeners();
  }

  Future<void> toggleMicrophone() async {
    _isMicMuted = !_isMicMuted;
    await _rtcService.toggleMicrophone(_isMicMuted);

    if (_activeRoom != null) {
      final mySeat = _activeRoom!.seats.firstWhere(
        (s) => s.userId == _currentUserId,
        orElse: () => VoiceRoomSeat(index: -1),
      );
      if (mySeat.index != -1) {
        mySeat.isMicOpen = !_isMicMuted;
      }
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerMuted = !_isSpeakerMuted;
    await _rtcService.toggleSpeaker(_isSpeakerMuted);
    notifyListeners();
  }

  void takeSeat(int seatIndex) {
    if (_activeRoom == null || seatIndex < 0 || seatIndex >= _activeRoom!.seats.length) return;
    final seat = _activeRoom!.seats[seatIndex];
    if (seat.isLocked || seat.isOccupied) return;

    final existingSeat = _activeRoom!.seats.firstWhere(
      (s) => s.userId == _currentUserId,
      orElse: () => VoiceRoomSeat(index: -1),
    );
    if (existingSeat.index != -1) {
      existingSeat.leave();
    }

    seat.occupy(
      uid: _currentUserId,
      name: _currentUserName,
      userRole: _activeRoom!.getUserRole(_currentUserId),
    );
    _isMicMuted = false;
    _rtcService.toggleMicrophone(false);

    _messages.add(
      VoiceRoomMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        senderName: 'System',
        text: '$_currentUserName took Seat #${seatIndex + 1}',
        isSystem: true,
      ),
    );
    notifyListeners();
  }

  void leaveSeat() {
    if (_activeRoom == null) return;
    final mySeat = _activeRoom!.seats.firstWhere(
      (s) => s.userId == _currentUserId,
      orElse: () => VoiceRoomSeat(index: -1),
    );
    if (mySeat.index != -1) {
      mySeat.leave();
      _isMicMuted = true;
      _rtcService.toggleMicrophone(true);
      _messages.add(
        VoiceRoomMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          text: '$_currentUserName stepped down to listeners',
          isSystem: true,
        ),
      );
      notifyListeners();
    }
  }

  void toggleLockSeat(int seatIndex) {
    if (_activeRoom == null) return;
    final role = _activeRoom!.getUserRole(_currentUserId);
    if (role != RoomRole.host && role != RoomRole.admin) return;

    final seat = _activeRoom!.seats[seatIndex];
    seat.isLocked = !seat.isLocked;
    if (seat.isLocked && seat.isOccupied) {
      seat.leave();
    }
    notifyListeners();
  }

  void muteSeatUser(int seatIndex) {
    if (_activeRoom == null) return;
    final role = _activeRoom!.getUserRole(_currentUserId);
    if (role != RoomRole.host && role != RoomRole.admin && role != RoomRole.moderator) return;

    final seat = _activeRoom!.seats[seatIndex];
    seat.isMutedByHost = !seat.isMutedByHost;
    if (seat.isMutedByHost && seat.userId == _currentUserId) {
      _isMicMuted = true;
      _rtcService.toggleMicrophone(true);
    }
    notifyListeners();
  }

  void kickUserFromSeat(int seatIndex) {
    if (_activeRoom == null) return;
    final role = _activeRoom!.getUserRole(_currentUserId);
    if (role != RoomRole.host && role != RoomRole.admin) return;

    final seat = _activeRoom!.seats[seatIndex];
    if (seat.isOccupied) {
      final kickedName = seat.userName;
      seat.leave();
      _messages.add(
        VoiceRoomMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          senderName: 'System',
          text: '$kickedName was removed from seat by Moderator',
          isSystem: true,
        ),
      );
      notifyListeners();
    }
  }

  void sendRoomChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _messages.add(
      VoiceRoomMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        text: text.trim(),
      ),
    );
    notifyListeners();
  }

  bool sendGift({
    required RoomGift gift,
    required String receiverName,
    required int Function() getCoinBalance,
    required void Function(int) deductCoins,
  }) {
    if (getCoinBalance() < gift.coinCost) {
      return false;
    }

    deductCoins(gift.coinCost);

    if (_lastSentGift?.id == gift.id) {
      _lastSentGiftCombo++;
    } else {
      _lastSentGift = gift;
      _lastSentGiftCombo = 1;
    }

    _giftAnimationTimer?.cancel();
    _giftAnimationTimer = Timer(const Duration(seconds: 4), () {
      _lastSentGift = null;
      _lastSentGiftCombo = 1;
      notifyListeners();
    });

    if (_activeRoom != null) {
      _activeRoom!.currentExp += gift.coinCost;
      if (_activeRoom!.currentExp >= _activeRoom!.maxExp) {
        _activeRoom!.roomLevel++;
        _activeRoom!.currentExp -= _activeRoom!.maxExp;
        _activeRoom!.maxExp = (_activeRoom!.maxExp * 1.5).toInt();
      }
    }

    _messages.add(
      VoiceRoomMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        text: 'sent ${gift.icon} ${gift.name} to $receiverName! x$_lastSentGiftCombo',
        isGiftNotice: true,
      ),
    );

    notifyListeners();
    return true;
  }

  void updateRoomSettings({
    required String title,
    required String announcement,
    required bool isPrivate,
    String? passcode,
    required RoomTag tag,
  }) {
    if (_activeRoom == null) return;
    _activeRoom!.title = title;
    _activeRoom!.announcement = announcement;
    _activeRoom!.isPrivate = isPrivate;
    _activeRoom!.passcode = passcode;
    _activeRoom!.tag = tag;
    notifyListeners();
  }

  @override
  void dispose() {
    _giftAnimationTimer?.cancel();
    _rtcService.dispose();
    _bgmService.dispose();
    super.dispose();
  }
}
