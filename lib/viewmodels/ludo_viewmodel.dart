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

  // Turn Timer Constants & State
  static const int turnDurationSeconds = 15;
  static const int warningThresholdSeconds = 5;

  int _remainingSeconds = turnDurationSeconds;
  Timer? _turnTimer;
  bool _isProcessingAction = false;
  int _turnSequenceId = 0;

  int get remainingSeconds => _remainingSeconds;
  double get timerProgress => (_remainingSeconds / turnDurationSeconds).clamp(0.0, 1.0);
  bool get isLowTime => _remainingSeconds <= warningThresholdSeconds && _remainingSeconds > 0;
  bool get isProcessingAction => _isProcessingAction;

  LudoViewModel() {
    initGame();
  }

  void initGame({List<LudoPlayer>? customPlayers}) {
    _cancelTimer();
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
    _isProcessingAction = false;
    _turnSequenceId = 0;
    notifyListeners();

    _startTurnTimer();
    _checkBotTurn();
  }

  void _startTurnTimer() {
    _cancelTimer();
    if (engine.state == LudoGameState.finished) return;

    _remainingSeconds = turnDurationSeconds;
    final currentSeq = ++_turnSequenceId;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentSeq != _turnSequenceId || engine.state == LudoGameState.finished) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleTurnTimeout(currentSeq);
      }
    });
  }

  void _cancelTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  /// Sync timer with server timestamp / network state (monotonic duration)
  void syncTurnTimer({required int secondsRemaining}) {
    _remainingSeconds = secondsRemaining.clamp(0, turnDurationSeconds);
    notifyListeners();
  }

  Future<void> _handleTurnTimeout(int sequenceId) async {
    if (sequenceId != _turnSequenceId || _isProcessingAction || engine.state == LudoGameState.finished) {
      return;
    }

    _isProcessingAction = true;
    notifyListeners();

    try {
      if (engine.state == LudoGameState.rolling) {
        // Automatic dice roll on timeout
        await _performRollLogic();
      }

      if (engine.state == LudoGameState.selectingToken && engine.currentDiceValue != null) {
        // Auto-move selection using smart decision engine
        final bestToken = engine.selectBestAutoMove(engine.currentDiceValue!);
        if (bestToken != null) {
          await Future.delayed(const Duration(milliseconds: 300));
          _performTokenMove(bestToken);
        } else {
          // No move available, pass turn
          await Future.delayed(const Duration(milliseconds: 400));
          _passTurn();
        }
      }
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  Future<void> rollDice() async {
    if (engine.state != LudoGameState.rolling || isRollingDice || _isProcessingAction) return;

    _isProcessingAction = true;
    await _performRollLogic();
    _isProcessingAction = false;
  }

  Future<void> _performRollLogic() async {
    isRollingDice = true;
    notifyListeners();

    // Dice roll animation duration
    await Future.delayed(const Duration(milliseconds: 350));

    int diceValue = _random.nextInt(6) + 1;
    engine.currentDiceValue = diceValue;
    isRollingDice = false;

    if (diceValue == 6) {
      engine.consecutiveSixes++;
      if (engine.consecutiveSixes == 3) {
        // 3 consecutive sixes penalty: turn ends immediately
        _passTurn();
        return;
      }
    } else {
      engine.consecutiveSixes = 0;
    }

    final movableTokens = engine.getMovableTokens(diceValue);

    if (movableTokens.isEmpty) {
      // No valid moves, display and pass turn
      engine.state = LudoGameState.selectingToken;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));
      _passTurn();
    } else if (movableTokens.length == 1 && !engine.currentPlayer.isBot) {
      // Auto move single movable token for smooth human UX
      engine.state = LudoGameState.selectingToken;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));
      _performTokenMove(movableTokens.first);
    } else {
      engine.state = LudoGameState.selectingToken;
      notifyListeners();

      if (engine.currentPlayer.isBot) {
        await Future.delayed(const Duration(milliseconds: 600));
        final botChoice = engine.selectBestAutoMove(diceValue);
        if (botChoice != null) {
          _performTokenMove(botChoice);
        } else {
          _passTurn();
        }
      }
    }
  }

  void selectToken(LudoToken token) {
    if (engine.state != LudoGameState.selectingToken || _isProcessingAction) return;
    if (engine.currentDiceValue == null) return;

    _performTokenMove(token);
  }

  void _performTokenMove(LudoToken token) {
    if (engine.currentDiceValue == null) return;
    int dice = engine.currentDiceValue!;

    bool moved = engine.moveToken(token, dice);
    if (moved) {
      if (engine.state == LudoGameState.finished) {
        _cancelTimer();
      } else {
        _startTurnTimer();
        _checkBotTurn();
      }
      notifyListeners();
    }
  }

  void _passTurn() {
    engine.nextTurn();
    _startTurnTimer();
    notifyListeners();
    _checkBotTurn();
  }

  void _checkBotTurn() async {
    if (engine.state == LudoGameState.finished) return;

    if (engine.currentPlayer.isBot && engine.state == LudoGameState.rolling) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (engine.currentPlayer.isBot && engine.state == LudoGameState.rolling) {
        rollDice();
      }
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
