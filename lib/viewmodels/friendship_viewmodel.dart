import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/realtime_socket_client.dart';

class FriendshipMission {
  final String id;
  final String title;
  final String description;
  final int target;
  int current;
  final int rewardXp;
  bool isCompleted;

  FriendshipMission({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.current = 0,
    required this.rewardXp,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'current': current,
        'rewardXp': rewardXp,
        'isCompleted': isCompleted,
      };

  factory FriendshipMission.fromJson(Map<String, dynamic> json) {
    return FriendshipMission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      target: json['target'] as int,
      current: json['current'] as int? ?? 0,
      rewardXp: json['rewardXp'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class FriendshipRelation {
  final String friendId;
  final String friendName;
  final String friendAvatar;
  int xp;
  int level;
  int dailyXpEarned;
  DateTime lastActivityTime;
  final List<FriendshipMission> dailyMissions;

  FriendshipRelation({
    required this.friendId,
    required this.friendName,
    this.friendAvatar = '',
    this.xp = 0,
    this.level = 1,
    this.dailyXpEarned = 0,
    DateTime? lastActivityTime,
    List<FriendshipMission>? dailyMissions,
  })  : lastActivityTime = lastActivityTime ?? DateTime.now(),
        dailyMissions = dailyMissions ??
            [
              FriendshipMission(
                id: 'm_ludo',
                title: 'Play Ludo Match Together',
                description: 'Complete 1 Ludo game with this friend',
                target: 1,
                rewardXp: 80,
              ),
              FriendshipMission(
                id: 'm_voice',
                title: 'Voice Chat 10 Mins',
                description: 'Hang out in the same voice room',
                target: 10,
                rewardXp: 100,
              ),
              FriendshipMission(
                id: 'm_gift',
                title: 'Send a Room Gift',
                description: 'Send any gift to celebrate',
                target: 1,
                rewardXp: 120,
              ),
            ];

  static const int maxDailyXp = 500; // Anti-farming cap

  String get badgeTitle {
    if (level >= 10) return 'Eternal Soulmates 💎';
    if (level >= 7) return 'Besties Forever ⭐';
    if (level >= 4) return 'Close Buddies 🌸';
    if (level >= 2) return 'Good Friends 🌿';
    return 'Acquaintances 🌱';
  }

  String get frameAsset {
    if (level >= 10) return 'assets/frames/diamond_bff_frame.png';
    if (level >= 7) return 'assets/frames/gold_bff_frame.png';
    if (level >= 4) return 'assets/frames/silver_bff_frame.png';
    return 'assets/frames/bronze_bff_frame.png';
  }

  Map<String, dynamic> toJson() => {
        'friendId': friendId,
        'friendName': friendName,
        'friendAvatar': friendAvatar,
        'xp': xp,
        'level': level,
        'dailyXpEarned': dailyXpEarned,
        'lastActivityTime': lastActivityTime.toIso8601String(),
        'dailyMissions': dailyMissions.map((m) => m.toJson()).toList(),
      };

  factory FriendshipRelation.fromJson(Map<String, dynamic> json) {
    return FriendshipRelation(
      friendId: json['friendId'] as String,
      friendName: json['friendName'] as String,
      friendAvatar: json['friendAvatar'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      dailyXpEarned: json['dailyXpEarned'] as int? ?? 0,
      lastActivityTime: json['lastActivityTime'] != null
          ? DateTime.tryParse(json['lastActivityTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      dailyMissions: (json['dailyMissions'] as List<dynamic>?)
          ?.map((m) => FriendshipMission.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FriendshipViewModel extends ChangeNotifier {
  final RealtimeSocketClient _socketClient = RealtimeSocketClient.instance;

  final List<FriendshipRelation> _relations = [
    FriendshipRelation(
      friendId: 'u_101',
      friendName: 'Sophia VIP',
      xp: 1850,
      level: 6,
      dailyXpEarned: 120,
    ),
    FriendshipRelation(
      friendId: 'u_102',
      friendName: 'Leo Gamer',
      xp: 640,
      level: 3,
      dailyXpEarned: 50,
    ),
    FriendshipRelation(
      friendId: 'u_103',
      friendName: 'Elena Song',
      xp: 220,
      level: 1,
      dailyXpEarned: 0,
    ),
  ];

  FriendshipViewModel() {
    _initSocketListeners();
  }

  List<FriendshipRelation> get relations => List.unmodifiable(_relations);

  void _initSocketListeners() {
    _socketClient.on('friendship:activity_synced', (data) {
      final friendId = data['friendId'] as String?;
      final xpGained = data['xpGained'] as int?;
      if (friendId != null && xpGained != null) {
        final rel = _relations.firstWhere(
          (r) => r.friendId == friendId,
          orElse: () => FriendshipRelation(friendId: '', friendName: ''),
        );
        if (rel.friendId.isNotEmpty) {
          rel.xp += xpGained;
          rel.level = (rel.xp / 300).floor() + 1;
          notifyListeners();
        }
      }
    });
  }

  bool addFriendshipActivity({
    required String friendId,
    required String activityType, // 'game', 'voice', 'gift'
    required int basePoints,
  }) {
    final relation = _relations.firstWhere(
      (r) => r.friendId == friendId,
      orElse: () => FriendshipRelation(friendId: '', friendName: ''),
    );

    if (relation.friendId.isEmpty) return false;

    // Reset daily XP if day changed
    final now = DateTime.now();
    if (relation.lastActivityTime.day != now.day) {
      relation.dailyXpEarned = 0;
      for (var mission in relation.dailyMissions) {
        mission.current = 0;
        mission.isCompleted = false;
      }
    }

    // Anti-farming check
    if (relation.dailyXpEarned >= FriendshipRelation.maxDailyXp) {
      return false; // Daily cap reached
    }

    final pointsToAdd = (basePoints).clamp(0, FriendshipRelation.maxDailyXp - relation.dailyXpEarned);
    relation.dailyXpEarned += pointsToAdd;
    relation.xp += pointsToAdd;
    relation.lastActivityTime = now;

    // Recalculate level (every 300 XP = +1 level)
    relation.level = (relation.xp / 300).floor() + 1;

    // Advance daily missions based on activity
    for (var m in relation.dailyMissions) {
      if (!m.isCompleted) {
        if (activityType == 'game' && m.id == 'm_ludo') {
          m.current += 1;
          if (m.current >= m.target) {
            m.isCompleted = true;
            relation.xp += m.rewardXp;
          }
        } else if (activityType == 'voice' && m.id == 'm_voice') {
          m.current += 5;
          if (m.current >= m.target) {
            m.isCompleted = true;
            relation.xp += m.rewardXp;
          }
        } else if (activityType == 'gift' && m.id == 'm_gift') {
          m.current += 1;
          if (m.current >= m.target) {
            m.isCompleted = true;
            relation.xp += m.rewardXp;
          }
        }
      }
    }

    // Synchronize to network socket
    _socketClient.emit('friendship:activity', {
      'friendId': friendId,
      'activityType': activityType,
      'points': pointsToAdd,
      'newXp': relation.xp,
      'newLevel': relation.level,
      'timestamp': now.toIso8601String(),
    });

    notifyListeners();
    return true;
  }
}
