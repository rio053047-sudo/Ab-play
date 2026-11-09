import 'package:flutter/foundation.dart';

enum EventType {
  daily,
  weekly,
  special,
}

class GameEvent {
  final String id;
  final String title;
  final String subtitle;
  final EventType type;
  final Duration remainingTime;
  final int rewardCoins;
  final int requiredProgress;
  int currentProgress;
  bool isClaimed;

  GameEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.remainingTime,
    required this.rewardCoins,
    required this.requiredProgress,
    this.currentProgress = 0,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= requiredProgress;
}

class EventsViewModel extends ChangeNotifier {
  final List<GameEvent> _events = [
    GameEvent(
      id: 'ev_1',
      title: '🎲 Daily Ludo Champion',
      subtitle: 'Play 3 Ludo matches with friends or bots',
      type: EventType.daily,
      remainingTime: const Duration(hours: 14, minutes: 22),
      rewardCoins: 200,
      requiredProgress: 3,
      currentProgress: 2,
    ),
    GameEvent(
      id: 'ev_2',
      title: '🎤 Voice Room Party Star',
      subtitle: 'Spend 15 minutes speaking or listening in voice rooms',
      type: EventType.daily,
      remainingTime: const Duration(hours: 14, minutes: 22),
      rewardCoins: 150,
      requiredProgress: 15,
      currentProgress: 15, // Complete ready to claim
    ),
    GameEvent(
      id: 'ev_3',
      title: '🏆 Weekly Gifting Gala',
      subtitle: 'Send 500 coins worth of gifts in any voice room',
      type: EventType.weekly,
      remainingTime: const Duration(days: 4, hours: 8),
      rewardCoins: 1000,
      requiredProgress: 500,
      currentProgress: 350,
    ),
  ];

  List<GameEvent> get events => List.unmodifiable(_events);

  bool claimReward(String eventId, void Function(int) addCoins) {
    final ev = _events.firstWhere((e) => e.id == eventId, orElse: () => _events.first);
    if (ev.isCompleted && !ev.isClaimed) {
      ev.isClaimed = true;
      addCoins(ev.rewardCoins);
      notifyListeners();
      return true;
    }
    return false;
  }
}
