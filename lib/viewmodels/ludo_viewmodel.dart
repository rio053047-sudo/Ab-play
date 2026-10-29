import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ludo/ludo_color.dart';
import '../models/ludo/ludo_engine.dart';
import '../models/ludo/ludo_player.dart';
import '../models/ludo/ludo_token.dart';

class LudoViewModel extends ChangeNotifier {
  late LudoEngine engine;
  final Random _random = Random();
  bool isRollingDice = false;

  LudoViewModel() {
    initGame();
  }

  void initGame({List<LudoPlayer>? customPlayers}) {
    final players = customPlayers ??
        [
          LudoPlayer(id: 'p1', name: 'Player 1 (You)', color: LudoColor.red),
          LudoPlayer(id: 'p2', name: 'Bot 1', color: LudoColor.green, isBot: true),
          LudoPlayer(id: 'p3', name: 'Bot 2', color: LudoColor.yellow, isBot: true),
          LudoPlayer(id: 'p4', name: 'Bot 3', color: LudoColor.blue, isBot: true),
        ];

    engine = LudoEngine(
      players: players,
      state: LudoGameState.rolling,
    );
    notifyListeners();

    _checkBotTurn();
  }

  Future<void> rollDice() async {
    if (engine.state != LudoGameState.rolling || isRollingDice) return;

    isRollingDice = true;
    notifyListeners();

    // Dice roll animation delay
    await Future.delayed(const Duration(milliseconds: 300));

    int diceValue = _random.nextInt(6) + 1;
    engine.currentDiceValue = diceValue;
    isRollingDice = false;

    if (diceValue == 6) {
      engine.consecutiveSixes++;
      if (engine.consecutiveSixes == 3) {
        // 3 consecutive sixes penalty: turn ends
        engine.nextTurn();
        notifyListeners();
        _checkBotTurn();
        return;
      }
    } else {
      engine.consecutiveSixes = 0;
    }

    final movableTokens = engine.getMovableTokens(diceValue);

    if (movableTokens.isEmpty) {
      // No valid moves, pass turn after brief display
      engine.state = LudoGameState.selectingToken;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));
      engine.nextTurn();
      notifyListeners();
      _checkBotTurn();
    } else if (movableTokens.length == 1 && !engine.currentPlayer.isBot) {
      // Auto move single movable token for smooth UX
      engine.state = LudoGameState.selectingToken;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));
      selectToken(movableTokens.first);
    } else {
      engine.state = LudoGameState.selectingToken;
      notifyListeners();

      if (engine.currentPlayer.isBot) {
        await Future.delayed(const Duration(milliseconds: 600));
        _handleBotSelectToken(movableTokens);
      }
    }
  }

  void selectToken(LudoToken token) {
    if (engine.state != LudoGameState.selectingToken) return;
    if (engine.currentDiceValue == null) return;

    bool moved = engine.moveToken(token, engine.currentDiceValue!);
    if (moved) {
      notifyListeners();
      if (engine.state != LudoGameState.finished) {
        _checkBotTurn();
      }
    }
  }

  void _handleBotSelectToken(List<LudoToken> movableTokens) {
    if (movableTokens.isEmpty) return;
    // Simple Bot AI: Prioritize entering main track or capturing over random move
    LudoToken choice = movableTokens.firstWhere(
      (t) => t.isInYard,
      orElse: () => movableTokens[_random.nextInt(movableTokens.length)],
    );
    selectToken(choice);
  }

  void _checkBotTurn() async {
    if (engine.state == LudoGameState.finished) return;

    if (engine.currentPlayer.isBot && engine.state == LudoGameState.rolling) {
      await Future.delayed(const Duration(milliseconds: 800));
      rollDice();
    }
  }
}
