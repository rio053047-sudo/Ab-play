import 'dart:math';
import 'package:flutter/foundation.dart';

enum WalletTransactionType {
  recharge,
  giftSent,
  giftReceived,
  coinBackReward,
  jackpotWon,
  storePurchase,
  familyContribution,
}

class WalletTransaction {
  final String id;
  final String idempotencyKey;
  final WalletTransactionType type;
  final int amount;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;
  final String details;

  WalletTransaction({
    required this.id,
    required this.idempotencyKey,
    required this.type,
    required this.amount,
    required this.senderId,
    required this.recipientId,
    DateTime? timestamp,
    required this.details,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ServerWalletService extends ChangeNotifier {
  static final ServerWalletService instance = ServerWalletService._internal();
  ServerWalletService._internal();

  final Set<String> _processedIdempotencyKeys = {};
  final List<WalletTransaction> _history = [];

  List<WalletTransaction> get history => List.unmodifiable(_history);

  // Economy Rules:
  // - Minimum gift value: 10 coins.
  // - Maximum gift value: 500,000 coins.
  // - Gifts below 100 coins do not qualify for coin-back.
  // - Gifts >= 100 coins qualify for recipient coin-back (e.g., 20% recipient reward).
  // - Rare jackpot: 1% chance for gifts >= 1,000 coins to trigger 5x jackpot reward.
  Map<String, dynamic> executeGiftTransaction({
    required String idempotencyKey,
    required String senderId,
    required String recipientId,
    required int giftValue,
    required String giftName,
    required int Function() getSenderBalance,
    required void Function(int) deductSenderCoins,
    required void Function(int) creditRecipientCoins,
  }) {
    if (_processedIdempotencyKeys.contains(idempotencyKey)) {
      return {'success': false, 'error': 'Duplicate transaction request (Idempotency error)'};
    }

    if (giftValue < 10 || giftValue > 500000) {
      return {'success': false, 'error': 'Gift value must be between 10 and 500,000 coins'};
    }

    if (getSenderBalance() < giftValue) {
      return {'success': false, 'error': 'Insufficient coin balance'};
    }

    _processedIdempotencyKeys.add(idempotencyKey);
    deductSenderCoins(giftValue);

    // Record sender transaction
    _history.insert(
      0,
      WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_s',
        idempotencyKey: idempotencyKey,
        type: WalletTransactionType.giftSent,
        amount: -giftValue,
        senderId: senderId,
        recipientId: recipientId,
        details: 'Sent "$giftName" ($giftValue coins)',
      ),
    );

    // Recipient Coin-Back calculations (Gifts >= 100 coins)
    int recipientCoinBack = 0;
    bool jackpotTriggered = false;
    int jackpotAmount = 0;

    if (giftValue >= 100) {
      // 25% coin back to recipient
      recipientCoinBack = (giftValue * 0.25).floor();
      creditRecipientCoins(recipientCoinBack);

      _history.insert(
        0,
        WalletTransaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}_cb',
          idempotencyKey: '${idempotencyKey}_cb',
          type: WalletTransactionType.coinBackReward,
          amount: recipientCoinBack,
          senderId: senderId,
          recipientId: recipientId,
          details: 'Recipient coin-back reward (+25% of $giftValue)',
        ),
      );

      // Rare Jackpot roll: 5% chance if giftValue >= 500
      if (giftValue >= 500 && Random().nextInt(100) < 5) {
        jackpotTriggered = true;
        jackpotAmount = giftValue * 2; // 2x jackpot
        creditRecipientCoins(jackpotAmount);

        _history.insert(
          0,
          WalletTransaction(
            id: 'tx_${DateTime.now().millisecondsSinceEpoch}_jp',
            idempotencyKey: '${idempotencyKey}_jp',
            type: WalletTransactionType.jackpotWon,
            amount: jackpotAmount,
            senderId: 'SYSTEM_JACKPOT',
            recipientId: recipientId,
            details: 'LUCKY JACKPOT WIN! (+$jackpotAmount coins)',
          ),
        );
      }
    }

    notifyListeners();

    return {
      'success': true,
      'senderDeduction': giftValue,
      'recipientReward': recipientCoinBack,
      'jackpotTriggered': jackpotTriggered,
      'jackpotAmount': jackpotAmount,
    };
  }
}
