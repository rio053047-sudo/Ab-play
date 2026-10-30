import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/viewmodels/home_viewmodel.dart';

void main() {
  group('HomeViewModel Tests', () {
    late HomeViewModel viewModel;

    setUp(() {
      viewModel = HomeViewModel();
    });

    test('Initial state values are correct', () {
      expect(viewModel.selectedTabIndex, 0);
      expect(viewModel.coinBalance, 12500);
      expect(viewModel.username, 'AbPlay_Gamer');
      expect(viewModel.shortcuts.length, 3);
      expect(viewModel.games.length, greaterThan(0));
      expect(viewModel.recentlyPlayedGames.length, greaterThan(0));
    });

    test('setSelectedTab updates index and notifies listeners', () {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      viewModel.setSelectedTab(2);

      expect(viewModel.selectedTabIndex, 2);
      expect(notifyCount, 1);
    });

    test('addCoins increases balance and notifies listeners', () {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      viewModel.addCoins(500);

      expect(viewModel.coinBalance, 13000);
      expect(notifyCount, 1);
    });
  });
}
