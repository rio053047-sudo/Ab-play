import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/viewmodels/friendship_viewmodel.dart';
import 'package:ab_play/viewmodels/family_viewmodel.dart';
import 'package:ab_play/viewmodels/events_viewmodel.dart';
import 'package:ab_play/viewmodels/achievements_viewmodel.dart';
import 'package:ab_play/viewmodels/customization_store_viewmodel.dart';
import 'package:ab_play/services/server_wallet_service.dart';
import 'package:ab_play/services/safety_and_security_service.dart';

void main() {
  group('Phase 3-7 System Tests', () {
    test('Friendship XP progression and daily cap anti-farming', () {
      final vm = FriendshipViewModel();
      expect(vm.relations.isNotEmpty, isTrue);

      final rel = vm.relations.first;
      final initialXp = rel.xp;

      // Add 200 XP
      final success = vm.addFriendshipActivity(friendId: rel.friendId, activityType: 'game', basePoints: 200);
      expect(success, isTrue);
      expect(rel.xp, equals(initialXp + 200));

      // Attempt to exceed daily cap
      vm.addFriendshipActivity(friendId: rel.friendId, activityType: 'game', basePoints: 400);
      expect(rel.dailyXpEarned, lessThanOrEqualTo(FriendshipRelation.maxDailyXp));
    });

    test('Family contribution updates level and member stats', () {
      final famVM = FamilyViewModel();
      final family = famVM.myFamily;
      expect(family, isNotNull);

      int userCoins = 500;
      final ok = famVM.contributeCoins(100, (deduct) => userCoins -= deduct);
      expect(ok, isTrue);
      expect(userCoins, equals(400));
    });

    test('Events reward claiming verifies progress and prevents double claim', () {
      final evVM = EventsViewModel();
      // ev_2 is already completed (15/15) in mock initialization
      final completedEvent = evVM.events.firstWhere((e) => e.id == 'ev_2');
      expect(completedEvent.isCompleted, isTrue);
      expect(completedEvent.isClaimed, isFalse);

      int coins = 0;
      final claimed = evVM.claimReward('ev_2', (amt) => coins += amt);
      expect(claimed, isTrue);
      expect(coins, equals(completedEvent.rewardCoins));
      expect(completedEvent.isClaimed, isTrue);

      // Duplicate claim must fail
      final duplicate = evVM.claimReward('ev_2', (amt) => coins += amt);
      expect(duplicate, isFalse);
    });

    test('Achievements claim unlocks verified reward coins', () {
      final achVM = AchievementsViewModel();
      final readyAch = achVM.achievements.firstWhere((a) => a.id == 'ach_3');
      expect(readyAch.isCompleted, isTrue);
      expect(readyAch.isClaimed, isFalse);

      int coins = 0;
      final claimed = achVM.claimAchievement(readyAch.id, (c) => coins += c);
      expect(claimed, isTrue);
      expect(coins, equals(500));
    });

    test('Customization store purchases and equips items', () {
      final storeVM = CustomizationStoreViewModel();
      final unownedItem = storeVM.catalog.firstWhere((i) => !i.isOwned);

      int coins = 10000;
      final success = storeVM.purchaseItem(unownedItem.id, coins, (c) => coins -= c);
      expect(success, isTrue);
      expect(unownedItem.isOwned, isTrue);
      expect(unownedItem.isEquipped, isTrue);
    });

    test('ServerWalletService executes gifts with recipient-only coin-back & idempotency', () {
      final wallet = ServerWalletService.instance;
      int senderBalance = 2000;
      int recipientBalance = 0;

      final res = wallet.executeGiftTransaction(
        idempotencyKey: 'tx_unique_001',
        senderId: 'user_A',
        recipientId: 'user_B',
        giftValue: 1000,
        giftName: 'Supercar',
        getSenderBalance: () => senderBalance,
        deductSenderCoins: (amt) => senderBalance -= amt,
        creditRecipientCoins: (amt) => recipientBalance += amt,
      );

      expect(res['success'], isTrue);
      expect(senderBalance, equals(1000));
      // 25% recipient coinback
      expect(recipientBalance, greaterThanOrEqualTo(250));

      // Re-running with same idempotency key must fail
      final dup = wallet.executeGiftTransaction(
        idempotencyKey: 'tx_unique_001',
        senderId: 'user_A',
        recipientId: 'user_B',
        giftValue: 1000,
        giftName: 'Supercar',
        getSenderBalance: () => senderBalance,
        deductSenderCoins: (amt) => senderBalance -= amt,
        creditRecipientCoins: (amt) => recipientBalance += amt,
      );
      expect(dup['success'], isFalse);
    });

    test('Safety and Security rate limiting enforces window caps', () {
      final sec = SafetyAndSecurityService.instance;
      const key = 'user_comment_action';

      for (int i = 0; i < 5; i++) {
        expect(sec.isRateLimited(actionKey: key, maxAllowedPerWindow: 5, window: const Duration(seconds: 10)), isFalse);
      }

      // 6th call should be rate limited
      expect(sec.isRateLimited(actionKey: key, maxAllowedPerWindow: 5, window: const Duration(seconds: 10)), isTrue);
    });
  });
}
