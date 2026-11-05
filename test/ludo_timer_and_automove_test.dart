import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/ludo/ludo_color.dart';
import 'package:ab_play/models/ludo/ludo_engine.dart';
import 'package:ab_play/models/ludo/ludo_player.dart';
import 'package:ab_play/models/ludo/ludo_token.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';

void main() {
  group('Ludo 15-Second Turn Timer and Auto-Move Tests', () {
    test('Timer initializes with 15 seconds remaining', () {
      final vm = LudoViewModel();
      expect(vm.remainingSeconds, 15);
      expect(vm.isLowTime, isFalse);
      expect(vm.timerProgress, 1.0);
      vm.dispose();
    });

    test('Warning state triggers when remainingSeconds <= 5', () {
      final vm = LudoViewModel();
      vm.syncTurnTimer(secondsRemaining: 5);
      expect(vm.remainingSeconds, 5);
      expect(vm.isLowTime, isTrue);

      vm.syncTurnTimer(secondsRemaining: 3);
      expect(vm.isLowTime, isTrue);

      vm.syncTurnTimer(secondsRemaining: 10);
      expect(vm.isLowTime, isFalse);
      vm.dispose();
    });

    test('selectBestAutoMove prioritizes knockout move over general advance', () {
      // Red start is index 0. Red token at step 2.
      // With dice 4, target step = 6, which lands on globalTrackIndex = (0 + 6 - 1) % 52 = 5 (unsafe spot).
      final redPlayer = LudoPlayer(
        id: 'p1',
        name: 'Red',
        color: LudoColor.red,
        tokens: [
          LudoToken(id: 0, color: LudoColor.red, step: 2), // will land on global index 5
          LudoToken(id: 1, color: LudoColor.red, step: 20), // non-capture
        ],
      );

      // Blue start is index 13.
      // To place blue token at globalTrackIndex = 5:
      // (13 + step - 1) % 52 == 5 => 13 + step - 1 = 57 => step = 45
      final bluePlayer = LudoPlayer(
        id: 'p2',
        name: 'Blue',
        color: LudoColor.blue,
        tokens: [
          LudoToken(id: 0, color: LudoColor.blue, step: 45),
        ],
      );

      expect(bluePlayer.tokens[0].globalTrackIndex, 5);

      final engine = LudoEngine(
        players: [redPlayer, bluePlayer],
        currentTurnIndex: 0,
      );

      final choice = engine.selectBestAutoMove(4);
      expect(choice, isNotNull);
      expect(choice!.id, 0); // Must pick the capture token (id 0)
    });

    test('selectBestAutoMove prioritizes reaching home (step 57)', () {
      final redPlayer = LudoPlayer(
        id: 'p1',
        name: 'Red',
        color: LudoColor.red,
        tokens: [
          LudoToken(id: 0, color: LudoColor.red, step: 55), // target with roll 2 = 57 (HOME!)
          LudoToken(id: 1, color: LudoColor.red, step: 10),
        ],
      );

      final engine = LudoEngine(
        players: [redPlayer],
        currentTurnIndex: 0,
      );

      final choice = engine.selectBestAutoMove(2);
      expect(choice, isNotNull);
      expect(choice!.id, 0); // Reaching home
    });

    test('selectBestAutoMove selects yard token when rolling 6 if no capture', () {
      final redPlayer = LudoPlayer(
        id: 'p1',
        name: 'Red',
        color: LudoColor.red,
        tokens: [
          LudoToken(id: 0, color: LudoColor.red, step: 0), // in yard
          LudoToken(id: 1, color: LudoColor.red, step: 15),
        ],
      );

      final engine = LudoEngine(
        players: [redPlayer],
        currentTurnIndex: 0,
      );

      final choice = engine.selectBestAutoMove(6);
      expect(choice, isNotNull);
      expect(choice!.step, 0); // Releases from yard
    });

    test('selectBestAutoMove returns null when no legal moves available', () {
      final redPlayer = LudoPlayer(
        id: 'p1',
        name: 'Red',
        color: LudoColor.red,
        tokens: [
          LudoToken(id: 0, color: LudoColor.red, step: 0),
          LudoToken(id: 1, color: LudoColor.red, step: 0),
        ],
      );

      final engine = LudoEngine(
        players: [redPlayer],
        currentTurnIndex: 0,
      );

      // Roll 3 with all tokens in yard has 0 legal moves
      final choice = engine.selectBestAutoMove(3);
      expect(choice, isNull);
    });
  });
}
