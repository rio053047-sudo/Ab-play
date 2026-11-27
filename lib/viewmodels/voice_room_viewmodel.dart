import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/voice_room.dart';
import '../services/audio_rtc_service.dart';
import '../services/room_bgm_service.dart';
import '../services/voice_room_repository.dart';

class VoiceRoomViewModel extends ChangeNotifier {
  final AudioRtcService _rtcService;
  final RoomBgmService _bgmService;
  final VoiceRoomRepository _repository;
  StreamSubscription<List<VoiceRoomSeat>>? _seatSubscription;
  StreamSubscription<Map<String, dynamic>>? _roomSubscription;
  StreamSubscription<Map<String, dynamic>?>? _memberSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _eventSubscription;
  StreamSubscription<int>? _walletSubscription;
  StreamSubscription<void>? _reconnectSubscription;
  StreamSubscription<Map<String, double>>? _audioLevelSubscription;

  VoiceRoomModel? _activeRoom;
  String _currentUserId = '';
  String _currentUserName = 'Player';
  int _coinBalance = 0;
  String? _lastError;
  bool? _hasSpeakerSeat;

  final List<VoiceRoomMessage> _messages = [];
  bool _isMicMuted = true;
  bool _isSpeakerMuted = false;
  RoomGift? _lastSentGift;
  int _lastSentGiftCombo = 1;
  String? _lastGiftEventId;
  bool _didLoadInitialRoomEvents = false;
  Timer? _giftAnimationTimer;

  static const List<RoomGift> standardGifts = [
    RoomGift(
        id: 'rose',
        name: 'Rose',
        coinCost: 10,
        icon: '🌹',
        effectName: 'Rose Petal Rain'),
    RoomGift(
        id: 'coffee',
        name: 'Coffee',
        coinCost: 20,
        icon: '☕',
        effectName: 'Warm Steam'),
    RoomGift(
        id: 'heart',
        name: 'Love Heart',
        coinCost: 50,
        icon: '💖',
        effectName: 'Heart Burst'),
    RoomGift(
        id: 'party_popper',
        name: 'Popper',
        coinCost: 100,
        icon: '🎉',
        effectName: 'Confetti Wave'),
    RoomGift(
        id: 'sports_car',
        name: 'Supercar',
        coinCost: 500,
        icon: '🏎️',
        effectName: 'Engine Roar'),
    RoomGift(
        id: 'diamond_ring',
        name: 'Ring',
        coinCost: 1000,
        icon: '💍',
        effectName: 'Diamond Sparkle'),
    RoomGift(
        id: 'rocket',
        name: 'Rocket',
        coinCost: 2000,
        icon: '🚀',
        effectName: 'Space Launch'),
    RoomGift(
        id: 'castle',
        name: 'Magic Castle',
        coinCost: 5000,
        icon: '🏰',
        effectName: 'Royal Fireworks'),
  ];

  VoiceRoomViewModel({
    AudioRtcService? rtcService,
    RoomBgmService? bgmService,
    VoiceRoomRepository? repository,
  })  : _rtcService = rtcService ?? RealAudioRtcService(),
        _bgmService = bgmService ?? RoomBgmService(),
        _repository = repository ?? VoiceRoomRepository();

  VoiceRoomModel? get activeRoom => _activeRoom;
  List<VoiceRoomMessage> get messages => List.unmodifiable(_messages);
  bool get isMicMuted => _isMicMuted;
  bool get isSpeakerMuted => _isSpeakerMuted;
  AudioRtcService get rtcService => _rtcService;
  RoomBgmService get bgmService => _bgmService;
  RoomGift? get lastSentGift => _lastSentGift;
  int get lastSentGiftCombo => _lastSentGiftCombo;
  String get currentUserId => _currentUserId;
  int get coinBalance => _coinBalance;
  String? get lastError => _lastError;
  Stream<List<VoiceRoomModel>> get publicRooms =>
      _repository.watchPublicRooms();
  Stream<List<Map<String, dynamic>>> get roomMembers => _activeRoom == null
      ? const Stream.empty()
      : _repository.watchMembers(_activeRoom!.id);
  Stream<List<Map<String, dynamic>>> get roomEvents => _activeRoom == null
      ? const Stream.empty()
      : _repository.watchEvents(_activeRoom!.id);
  Stream<List<Map<String, dynamic>>> get giftHistory => _activeRoom == null
      ? const Stream.empty()
      : _repository.watchGiftHistory(_activeRoom!.id);
  Stream<Map<String, dynamic>> get dailyTask => _activeRoom == null
      ? const Stream.empty()
      : _repository.watchDailyTask(_activeRoom!.id);

  void setLoggedInUser(String uid, String name) {
    _currentUserId = uid;
    _currentUserName = name;
    _walletSubscription?.cancel();
    if (uid.isNotEmpty) {
      _walletSubscription = _repository.watchWallet().listen((balance) {
        _coinBalance = balance;
        notifyListeners();
      }, onError: _setError);
    }
  }

  Future<void> enterRoom(VoiceRoomModel room, {String? password}) async {
    final (serverRoom, credentials) =
        await _repository.joinRoom(room.id, password: password);
    await _startRoom(serverRoom, credentials);
  }

  Future<void> createAndEnterRoom(
      {required String name,
      String description = '',
      required bool isPrivate,
      String? password,
      XFile? coverImage}) async {
    final (serverRoom, credentials) = await _repository.createRoom(
        name: name,
        description: description,
        isPrivate: isPrivate,
        password: password,
        coverImage: coverImage);
    await _startRoom(serverRoom, credentials);
  }

  Future<void> _startRoom(
      VoiceRoomModel room, VoiceRtcCredentials credentials) async {
    _activeRoom = room;
    _messages.clear();
    _lastGiftEventId = null;
    _didLoadInitialRoomEvents = false;
    _messages.add(
      VoiceRoomMessage(
        id: 'msg_welcome',
        senderId: 'system',
        senderName: 'Ab-Play System',
        text:
            'Welcome to "${room.title}"! Enjoy the party and follow community rules.',
        isSystem: true,
      ),
    );

    await _repository.attachPresence(room.id);
    await _rtcService.joinChannel(
      roomId: credentials.channel,
      userId: _currentUserId,
      isSpeaker: credentials.publisher,
      appId: credentials.appId,
      token: credentials.token,
      rtcUid: credentials.uid,
      refreshToken: () async =>
          (await _repository.refreshRtcToken(room.id)).token,
    );

    _isMicMuted = true;
    _hasSpeakerSeat = credentials.publisher;
    _watchRoomState(room.id);
    _reconnectSubscription?.cancel();
    _reconnectSubscription =
        _rtcService.reconnected.listen((_) => unawaited(_recoverRoom(room.id)));
    notifyListeners();
  }

  Future<void> _recoverRoom(String roomId) async {
    try {
      final (room, credentials) = await _repository.joinRoom(roomId);
      await _repository.attachPresence(roomId);
      _hasSpeakerSeat = credentials.publisher;
      await _rtcService.updatePublisherRole(
          canPublish: _hasSpeakerSeat!, token: credentials.token);
    } catch (error) {
      _setError(error);
    }
  }

  void _watchRoomState(String roomId) {
    _seatSubscription?.cancel();
    _roomSubscription?.cancel();
    _memberSubscription?.cancel();
    _eventSubscription?.cancel();
    _seatSubscription = _repository.watchSeats(roomId).listen((seats) {
      if (_activeRoom?.id != roomId) return;
      _activeRoom!.seats = seats;
      _applyAudioLevels();
      final mine =
          seats.where((seat) => seat.userId == _currentUserId).firstOrNull;
      final hasSeat = mine != null;
      if (_hasSpeakerSeat != null && _hasSpeakerSeat != hasSeat) {
        _hasSpeakerSeat = hasSeat;
        unawaited(_syncRtcRole(roomId, hasSeat));
      } else {
        _hasSpeakerSeat ??= hasSeat;
      }
      if (mine?.isMutedByHost == true && !_isMicMuted) {
        _isMicMuted = true;
        unawaited(_rtcService.toggleMicrophone(true));
      }
      notifyListeners();
    }, onError: _setError);
    _audioLevelSubscription?.cancel();
    _audioLevelSubscription = _rtcService.remoteAudioLevels.listen((levels) {
      if (_activeRoom?.id != roomId) return;
      for (final seat in _activeRoom!.seats) {
        seat.isSpeaking =
            seat.rtcUid != null && (levels['${seat.rtcUid}'] ?? 0) > .12;
      }
      final localSeat = _activeRoom!.seats
          .where((seat) => seat.userId == _currentUserId)
          .firstOrNull;
      if (localSeat != null) {
        localSeat.isSpeaking = _rtcService.localAudioLevel.value > .12;
      }
      notifyListeners();
    });
    _roomSubscription = _repository.watchRoom(roomId).listen((data) {
      if (_activeRoom?.id != roomId || data.isEmpty) return;
      if (data['status'] == 'closed') {
        _activeRoom = null;
        unawaited(_rtcService.leaveChannel());
        notifyListeners();
        return;
      }
      _activeRoom!
        ..title = data['name'] as String? ?? _activeRoom!.title
        ..description =
            data['description'] as String? ?? _activeRoom!.description
        ..coverPath = data['coverPath'] as String? ?? _activeRoom!.coverPath
        ..announcement =
            data['announcement'] as String? ?? _activeRoom!.announcement
        ..isLocked = data['locked'] == true
        ..onlineCount = (data['participantCount'] as num?)?.toInt() ??
            _activeRoom!.onlineCount
        ..roomLevel = (data['level'] as num?)?.toInt() ?? _activeRoom!.roomLevel
        ..currentExp =
            (data['experience'] as num?)?.toInt() ?? _activeRoom!.currentExp
        ..maxExp = (data['nextLevelExperience'] as num?)?.toInt() ??
            _activeRoom!.maxExp;
      notifyListeners();
    }, onError: _setError);
    _memberSubscription = _repository.watchMember(roomId).listen((member) {
      if (_activeRoom?.id != roomId ||
          member == null ||
          member['active'] == true) {
        return;
      }
      if (member['removedByModeration'] == true) {
        _activeRoom = null;
        unawaited(_rtcService.leaveChannel());
        notifyListeners();
      }
    }, onError: _setError);
    _eventSubscription = _repository.watchEvents(roomId).listen((events) {
      if (_activeRoom?.id != roomId) return;
      _messages
        ..clear()
        ..addAll(events.map((event) {
          final payload = event['payload'] is Map
              ? Map<String, dynamic>.from(event['payload'] as Map)
              : <String, dynamic>{};
          final type = event['type'] as String? ?? 'room event';
          final name = payload['senderName'] as String? ??
              payload['name'] as String? ??
              'Ab-Play';
          final isGift = type == 'giftSent';
          final isChat = type == 'chatMessage';
          final text = isGift
              ? 'sent ${payload['giftIcon'] ?? ''} ${payload['giftName'] ?? 'gift'} to ${payload['recipientName'] ?? 'a participant'}'
              : isChat
                  ? payload['text'] as String? ?? ''
                  : type;
          return VoiceRoomMessage(
              id: event['id'] as String? ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              senderId: event['actorUid'] as String? ?? '',
              senderName: name,
              text: text,
              isSystem: !isGift && !isChat,
              isGiftNotice: isGift);
        }));
      final giftEvent = events.reversed
          .where((event) => event['type'] == 'giftSent')
          .firstOrNull;
      if (!_didLoadInitialRoomEvents) {
        _didLoadInitialRoomEvents = true;
        _lastGiftEventId = giftEvent?['id'] as String?;
      } else if (giftEvent != null && giftEvent['id'] != _lastGiftEventId) {
        _lastGiftEventId = giftEvent['id'] as String?;
        final payload = giftEvent['payload'] is Map
            ? Map<String, dynamic>.from(giftEvent['payload'] as Map)
            : <String, dynamic>{};
        _lastSentGift = standardGifts
            .where((gift) => gift.id == payload['giftId'])
            .firstOrNull;
        _lastSentGiftCombo = 1;
        _giftAnimationTimer?.cancel();
        _giftAnimationTimer = Timer(const Duration(seconds: 4), () {
          _lastSentGift = null;
          notifyListeners();
        });
      }
      notifyListeners();
    }, onError: _setError);
  }

  void _applyAudioLevels() {
    for (final seat in _activeRoom!.seats) {
      if (seat.userId == _currentUserId) {
        seat.isSpeaking = _rtcService.localAudioLevel.value > .12;
      }
    }
  }

  Future<void> _syncRtcRole(String roomId, bool canPublish) async {
    try {
      final credentials = await _repository.refreshRtcToken(roomId);
      await _rtcService.updatePublisherRole(
          canPublish: canPublish, token: credentials.token);
      if (!canPublish) _isMicMuted = true;
      notifyListeners();
    } catch (error) {
      _setError(error);
    }
  }

  void _setError(Object error) {
    _lastError = error.toString().replaceFirst('Bad state: ', '');
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    if (_activeRoom != null) {
      final id = _activeRoom!.id;
      try {
        await _rtcService.leaveChannel();
      } catch (error) {
        _setError(error);
      }
      try {
        await _repository.leaveRoom(id);
      } catch (error) {
        _setError(error);
      }
    }
    await _seatSubscription?.cancel();
    await _roomSubscription?.cancel();
    await _memberSubscription?.cancel();
    await _eventSubscription?.cancel();
    await _reconnectSubscription?.cancel();
    await _audioLevelSubscription?.cancel();
    _bgmService.stop();
    _activeRoom = null;
    notifyListeners();
  }

  Future<void> toggleMicrophone() async {
    if (_activeRoom == null) return;
    final muted = !_isMicMuted;
    try {
      await _repository.setMicrophone(_activeRoom!.id, muted);
      await _rtcService.toggleMicrophone(muted);
      _isMicMuted = muted;
      notifyListeners();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerMuted = !_isSpeakerMuted;
      await _rtcService.toggleSpeaker(_isSpeakerMuted);
      notifyListeners();
    } catch (error) {
      _setError(error);
    }
  }

  void takeSeat(int seatIndex) {
    if (_activeRoom == null ||
        seatIndex < 0 ||
        seatIndex >= _activeRoom!.seats.length) {
      return;
    }
    final seat = _activeRoom!.seats[seatIndex];
    if (seat.isLocked || seat.isOccupied) return;

    unawaited(_assignSeat(seatIndex));
  }

  Future<void> _assignSeat(int index) async {
    try {
      await _repository.assignSeat(_activeRoom!.id, index);
      final rtc = await _repository.refreshRtcToken(_activeRoom!.id);
      await _rtcService.updatePublisherRole(canPublish: true, token: rtc.token);
      _isMicMuted = true;
      await _repository.setMicrophone(_activeRoom!.id, true);
    } catch (error) {
      _setError(error);
    }
  }

  void leaveSeat() {
    if (_activeRoom == null) return;
    final mySeat = _activeRoom!.seats.firstWhere(
      (s) => s.userId == _currentUserId,
      orElse: () => VoiceRoomSeat(index: -1),
    );
    if (mySeat.index != -1) {
      unawaited(_stepDown());
      _isMicMuted = true;
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

  Future<void> _stepDown() async {
    try {
      await _repository.leaveSeat(_activeRoom!.id);
      final rtc = await _repository.refreshRtcToken(_activeRoom!.id);
      await _rtcService.updatePublisherRole(
          canPublish: false, token: rtc.token);
    } catch (error) {
      _setError(error);
    }
  }

  void toggleLockSeat(int seatIndex) {
    if (_activeRoom == null) return;
    final role = _activeRoom!.getUserRole(_currentUserId);
    if (role != RoomRole.host && role != RoomRole.admin) return;

    final seat = _activeRoom!.seats[seatIndex];
    unawaited(_repository.update(_activeRoom!.id, 'seatLock', {
      'seatIndex': seatIndex,
      'locked': !seat.isLocked
    }).catchError(_setError));
  }

  void muteSeatUser(int seatIndex) {
    if (_activeRoom == null) return;
    final role = _activeRoom!.getUserRole(_currentUserId);
    if (role != RoomRole.host &&
        role != RoomRole.admin &&
        role != RoomRole.moderator) {
      return;
    }

    final seat = _activeRoom!.seats[seatIndex];
    if (seat.userId == null) return;
    unawaited(_repository
        .moderate(_activeRoom!.id, seat.userId!,
            seat.isMutedByHost ? 'unmute' : 'mute')
        .catchError(_setError));
  }

  void kickUserFromSeat(int seatIndex) {
    if (_activeRoom == null) return;
    final role = _activeRoom!.getUserRole(_currentUserId);
    if (role != RoomRole.host && role != RoomRole.admin) return;

    final seat = _activeRoom!.seats[seatIndex];
    if (seat.isOccupied) {
      if (seat.userId != null) {
        unawaited(_repository
            .moderate(_activeRoom!.id, seat.userId!, 'kick')
            .catchError(_setError));
      }
    }
  }

  void sendRoomChatMessage(String text) {
    final room = _activeRoom;
    if (room == null || text.trim().isEmpty) return;
    unawaited(_repository.sendChat(room.id, text.trim()).catchError(_setError));
  }

  Future<bool> sendGift({
    required RoomGift gift,
    required String receiverName,
    required String receiverUid,
  }) {
    if (_activeRoom == null) return Future.value(false);
    return _repository
        .sendGift(_activeRoom!.id, receiverUid, gift.id)
        .then((_) => true)
        .catchError((error) {
      _setError(error);
      return false;
    });
  }

  void updateRoomSettings({
    required String title,
    required String announcement,
    required bool isPrivate,
    String? passcode,
    required RoomTag tag,
  }) {
    if (_activeRoom == null) return;
    unawaited(_repository
        .update(_activeRoom!.id, 'details', {
          'name': title,
          'description': _activeRoom!.description,
          'visibility': isPrivate ? 'private' : 'public',
          if (passcode != null && passcode.isNotEmpty) 'password': passcode,
        })
        .then((_) => _repository.update(
            _activeRoom!.id, 'announcement', {'announcement': announcement}))
        .catchError(_setError));
  }

  Future<void> toggleRoomLock(bool locked) async {
    if (_activeRoom == null) return;
    try {
      await _repository.update(_activeRoom!.id, 'lock', {'locked': locked});
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> transferHost(String targetUid) async {
    if (_activeRoom == null) return;
    try {
      await _repository
          .update(_activeRoom!.id, 'transferHost', {'targetUid': targetUid});
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> assignSpeaker(String targetUid, int seatIndex) async {
    if (_activeRoom == null) return;
    try {
      await _repository.assignSeat(_activeRoom!.id, seatIndex,
          targetUid: targetUid);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> moderateMember(String targetUid, String action) async {
    if (_activeRoom == null) return;
    try {
      await _repository.moderate(_activeRoom!.id, targetUid, action);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> setModerator(String targetUid, bool moderator) async {
    if (_activeRoom == null) return;
    try {
      await _repository.setModerator(_activeRoom!.id, targetUid, moderator);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> reportUser(String targetUid, String reason) async {
    if (_activeRoom == null) return;
    try {
      await _repository.reportUser(_activeRoom!.id, targetUid, reason);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> blockUser(String targetUid) async {
    try {
      await _repository.blockUser(targetUid);
    } catch (error) {
      _setError(error);
    }
  }

  @override
  void dispose() {
    _seatSubscription?.cancel();
    _roomSubscription?.cancel();
    _memberSubscription?.cancel();
    _eventSubscription?.cancel();
    _walletSubscription?.cancel();
    _reconnectSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    _giftAnimationTimer?.cancel();
    _rtcService.dispose();
    _bgmService.dispose();
    super.dispose();
  }
}
