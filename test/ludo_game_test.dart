import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/ludo/ludo_color.dart';
import 'package:ab_play/models/ludo/ludo_engine.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';

void main() {
  group('Ludo Engine and ViewModel Tests', () {
    late LudoViewModel vm;

    setUp(() {
      vm = LudoViewModel();
    });

    test('Initial game setup creates 4 players with 4 tokens each in yard', () {
      expect(vm.engine.players.length, 4);
      for (var p in vm.engine.players) {
        expect(p.tokens.length, 4);
        expect(p.tokens.every((t) => t.isInYard), isTrue);
      }
      expect(vm.engine.state, LudoGameState.rolling);
      expect(vm.engine.currentPlayer.color, LudoColor.red);
    });

    test('Rolling a 6 allows exit from yard to step 1', () {
      final redPlayer = vm.engine.players[0];
      final token0 = redPlayer.tokens[0];

      expect(vm.engine.canMovableToken(token0, 6), isTrue);
      expect(vm.engine.canMovableToken(token0, 5), isFalse);

      vm.engine.currentDiceValue = 6;
      bool moved = vm.engine.moveToken(token0, 6);

      expect(moved, isTrue);
      expect(token0.step, 1);
      expect(token0.globalTrackIndex, 0); // Red start track index
    });

    test('Token capture sends enemy token back to yard', () {
      final redPlayer = vm.engine.players[0]; // Red start index = 0
      final greenPlayer = vm.engine.players[1]; // Green start index = 39

      // Move Red token to index 14
      final redToken = redPlayer.tokens[0];
      final greenToken = greenPlayer.tokens[0];

      redToken.step = 1; // index 0 (safe spot)
      greenToken.step = 28; // Green start 39 + 28 - 1 = 66 -> % 52 = 14 (non-safe spot)

      vm.engine.currentTurnIndex = 0; // Red's turn
      vm.engine.moveToken(redToken, 14); // step becomes 15 -> index 14

      expect(redToken.globalTrackIndex, 14);
      expect(greenToken.isInYard, isTrue); // Captured!
    });

    test('Winning condition when all 4 tokens reach home step 57', () {
      final redPlayer = vm.engine.players[0];
      for (var t in redPlayer.tokens) {
        t.step = 57;
      }

      expect(redPlayer.hasWon, isTrue);
    });
  });
}
