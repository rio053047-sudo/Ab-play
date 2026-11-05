import 'package:flutter/foundation.dart';

enum RoomRole {
  host,
  admin,
  moderator,
  speaker,
  listener,
}

enum RoomTag {
  party,
  music,
  gaming,
  chat,
  singing,
}

class VoiceRoomSeat {
  final int index;
  String? userId;
  String? userName;
  String? userAvatar;
  bool isLocked;
  bool isMutedByHost;
  bool isMicOpen;
  bool isSpeaking;
  RoomRole role;

  VoiceRoomSeat({
    required this.index,
    this.userId,
    this.userName,
    this.userAvatar,
    this.isLocked = false,
    this.isMutedByHost = false,
    this.isMicOpen = false,
    this.isSpeaking = false,
    this.role = RoomRole.listener,
  });

  bool get isOccupied => userId != null;

  void occupy({
    required String uid,
    required String name,
    String? avatar,
    RoomRole userRole = RoomRole.speaker,
  }) {
    userId = uid;
    userName = name;
    userAvatar = avatar;
    role = userRole;
    isMicOpen = true;
    isSpeaking = false;
  }

  void leave() {
    userId = null;
    userName = null;
    userAvatar = null;
    isMicOpen = false;
    isSpeaking = false;
    role = RoomRole.listener;
  }
}

class VoiceRoomMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool isSystem;
  final bool isGiftNotice;
  final DateTime timestamp;

  VoiceRoomMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isSystem = false,
    this.isGiftNotice = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RoomGift {
  final String id;
  final String name;
  final int coinCost;
  final String icon;
  final String effectName;

  const RoomGift({
    required this.id,
    required this.name,
    required this.coinCost,
    required this.icon,
    required this.effectName,
  });
}

class VoiceRoomModel {
  final String id;
  String title;
  String description;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  RoomTag tag;
  bool isPrivate;
  String? passcode;
  int roomLevel;
  int currentExp;
  int maxExp;
  int maxCapacity;
  int onlineCount;
  String announcement;
  List<VoiceRoomSeat> seats;
  List<String> adminIds;
  List<String> bannedUserIds;

  VoiceRoomModel({
    required this.id,
    required this.title,
    this.description = 'Welcome to the Ab-Play Voice Room!',
    required this.hostId,
    required this.hostName,
    this.hostAvatar = '',
    this.tag = RoomTag.party,
    this.isPrivate = false,
    this.passcode,
    this.roomLevel = 1,
    this.currentExp = 120,
    this.maxExp = 1000,
    this.maxCapacity = 50,
    this.onlineCount = 1,
    this.announcement = 'Welcome to our room! Please be respectful and enjoy the party.',
    List<VoiceRoomSeat>? seats,
    List<String>? adminIds,
    List<String>? bannedUserIds,
  })  : seats = seats ?? List.generate(8, (index) => VoiceRoomSeat(index: index)),
        adminIds = adminIds ?? [],
        bannedUserIds = bannedUserIds ?? [];

  RoomRole getUserRole(String uid) {
    if (uid == hostId) return RoomRole.host;
    if (adminIds.contains(uid)) return RoomRole.admin;
    final seat = seats.firstWhere(
      (s) => s.userId == uid,
      orElse: () => VoiceRoomSeat(index: -1),
    );
    if (seat.index != -1) return seat.role;
    return RoomRole.listener;
  }
}
