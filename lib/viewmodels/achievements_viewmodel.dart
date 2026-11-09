import 'package:flutter/foundation.dart';

class AchievementItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int maxLevel;
  int currentLevel;
  int progress;
  int targetProgress;
  int rewardCoins;
  bool isClaimed;

  AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.maxLevel = 3,
    this.currentLevel = 1,
    this.progress = 0,
    required this.targetProgress,
    required this.rewardCoins,
    this.isClaimed = false,
  });

  bool get isCompleted => progress >= targetProgress;
}

class AchievementsViewModel extends ChangeNotifier {
  final List<AchievementItem> _achievements = [
    AchievementItem(
      id: 'ach_1',
      title: 'First Game Winner',
      description: 'Win your first Ludo party match',
      icon: '🏆',
      progress: 1,
      targetProgress: 1,
      rewardCoins: 100,
      isClaimed: true,
    ),
    AchievementItem(
      id: 'ach_2',
      title: 'Voice Room Star',
      description: 'Host or speak in voice rooms for 30 minutes',
      icon: '⭐',
      progress: 25,
      targetProgress: 30,
      rewardCoins: 250,
    ),
    AchievementItem(
      id: 'ach_3',
      title: 'Gift Master',
      description: 'Send 10 gifts in any voice room',
      icon: '🎁',
      progress: 10,
      targetProgress: 10,
      rewardCoins: 500,
      isClaimed: false, // Ready to claim
    ),
    AchievementItem(
      id: 'ach_4',
      title: 'Social Butterfly',
      description: 'Add 5 verified friends on Ab-Play',
      icon: '🦋',
      progress: 4,
      targetProgress: 5,
      rewardCoins: 150,
    ),
    AchievementItem(
      id: 'ach_5',
      title: 'Daily Login Streak',
      description: 'Login 7 consecutive days',
      icon: '🔥',
      progress: 5,
      targetProgress: 7,
      rewardCoins: 300,
    ),
    AchievementItem(
      id: 'ach_6',
      title: 'Friendship Champion',
      description: 'Reach Level 5 with any friend',
      icon: '💖',
      progress: 5,
      targetProgress: 5,
      rewardCoins: 400,
      isClaimed: false, // Ready to claim
    ),
    AchievementItem(
      id: 'ach_7',
      title: 'Family Contributor',
      description: 'Donate 500 coins to your club/family',
      icon: '🛡️',
      progress: 1200,
      targetProgress: 500,
      rewardCoins: 350,
      isClaimed: true,
    ),
    AchievementItem(
      id: 'ach_8',
      title: 'Event Champion',
      description: 'Complete 10 limited-time daily events',
      icon: '🥇',
      progress: 6,
      targetProgress: 10,
      rewardCoins: 600,
    ),
  ];

  List<AchievementItem> get achievements => List.unmodifiable(_achievements);

  bool claimAchievement(String id, void Function(int) addCoins) {
    final item = _achievements.firstWhere((a) => a.id == id, orElse: () => _achievements.first);
    if (item.isCompleted && !item.isClaimed) {
      item.isClaimed = true;
      addCoins(item.rewardCoins);
      notifyListeners();
      return true;
    }
    return false;
  }
}
