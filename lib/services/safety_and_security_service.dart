import 'package:flutter/foundation.dart';

class SafetyAndSecurityService extends ChangeNotifier {
  static final SafetyAndSecurityService instance = SafetyAndSecurityService._internal();
  SafetyAndSecurityService._internal();

  final Set<String> _blockedUserIds = {};
  final List<Map<String, dynamic>> _reportedCases = [];

  // Rate Limiting tracker: user_action -> timestamps
  final Map<String, List<DateTime>> _rateLimitBuckets = {};

  Set<String> get blockedUserIds => Set.unmodifiable(_blockedUserIds);
  List<Map<String, dynamic>> get reportedCases => List.unmodifiable(_reportedCases);

  bool isRateLimited({
    required String actionKey,
    required int maxAllowedPerWindow,
    required Duration window,
  }) {
    final now = DateTime.now();
    final timestamps = _rateLimitBuckets.putIfAbsent(actionKey, () => []);

    // Evict old timestamps
    timestamps.removeWhere((t) => now.difference(t) > window);

    if (timestamps.length >= maxAllowedPerWindow) {
      return true; // Rate limit exceeded
    }

    timestamps.add(now);
    return false;
  }

  void blockUser(String userId) {
    _blockedUserIds.add(userId);
    notifyListeners();
  }

  void unblockUser(String userId) {
    _blockedUserIds.remove(userId);
    notifyListeners();
  }

  bool isUserBlocked(String userId) => _blockedUserIds.contains(userId);

  void reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String contextRoomOrChat,
  }) {
    _reportedCases.insert(0, {
      'id': 'rep_${DateTime.now().millisecondsSinceEpoch}',
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'context': contextRoomOrChat,
      'status': 'pending_review',
      'timestamp': DateTime.now(),
    });
    notifyListeners();
  }
}
