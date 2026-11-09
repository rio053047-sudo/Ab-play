import 'package:flutter/foundation.dart';

class FriendshipRelation {
  final String friendId;
  final String friendName;
  final String friendAvatar;
  int xp;
  int level;
  int dailyXpEarned;
  DateTime lastActivityTime;
  final List<String> completedDailyMissions;

  FriendshipRelation({
    required this.friendId,
    required this.friendName,
    this.friendAvatar = '',
    this.xp = 0,
    this.level = 1,
    this.dailyXpEarned = 0,
    DateTime? lastActivityTime,
    List<String>? completedDailyMissions,
  })  : lastActivityTime = lastActivityTime ?? DateTime.now(),
        completedDailyMissions = completedDailyMissions ?? [];

  static const int maxDailyXp = 500; // Anti-farming cap

  String get badgeTitle {
    if (level >= 10) return 'Besties Forever 💎';
    if (level >= 5) return 'Close Buddies ⭐';
    if (level >= 3) return 'Good Friends 🌸';
    return 'Acquaintances 🌱';
  }

  String get frameAsset {
    if (level >= 10) return 'assets/frames/diamond_bff_frame.png';
    if (level >= 5) return 'assets/frames/gold_bff_frame.png';
    return 'assets/frames/silver_bff_frame.png';
  }
}

class FriendshipViewModel extends ChangeNotifier {
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

  List<FriendshipRelation> get relations => List.unmodifiable(_relations);

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
      relation.completedDailyMissions.clear();
    }

    // Anti-farming check
    if (relation.dailyXpEarned >= FriendshipRelation.maxDailyXp) {
      return false; // Cap reached
    }

    final pointsToAdd = (basePoints).clamp(0, FriendshipRelation.maxDailyXp - relation.dailyXpEarned);
    relation.dailyXpEarned += pointsToAdd;
    relation.xp += pointsToAdd;
    relation.lastActivityTime = now;

    // Recalculate level (every 300 XP = +1 level)
    relation.level = (relation.xp / 300).floor() + 1;

    notifyListeners();
    return true;
  }
}
