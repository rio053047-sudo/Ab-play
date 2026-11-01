import 'ludo_color.dart';
import 'ludo_player.dart';
import 'ludo_token.dart';

enum LudoGameState {
  waiting,
  rolling,
  selectingToken,
  finished,
}

class LudoEngine {
  static const List<int> safeTrackIndices = [0, 8, 13, 21, 26, 34, 39, 47];

  List<LudoPlayer> players;
  int currentTurnIndex;
  int? currentDiceValue;
  LudoGameState state;
  LudoColor? winner;
  int consecutiveSixes;

  LudoEngine({
    required this.players,
    this.currentTurnIndex = 0,
    this.currentDiceValue,
    this.state = LudoGameState.waiting,
    this.winner,
    this.consecutiveSixes = 0,
  });

  LudoPlayer get currentPlayer => players[currentTurnIndex];

  bool canMovableToken(LudoToken token, int dice) {
    if (token.color != currentPlayer.color) return false;
    if (token.isHome) return false;

    if (token.isInYard) {
      return dice == 6;
    }

    // On track or home stretch (57 is winning step)
    if (token.step + dice <= 57) {
      return true;
    }

    return false;
  }

  List<LudoToken> getMovableTokens(int dice) {
    return currentPlayer.tokens
        .where((t) => canMovableToken(t, dice))
        .toList();
  }

  void nextTurn() {
    consecutiveSixes = 0;
    currentDiceValue = null;
    currentTurnIndex = (currentTurnIndex + 1) % players.length;
    state = LudoGameState.rolling;
  }

  /// Evaluates smart/fair auto-move selection:
  /// 1. Knock out opponent (highest priority)
  /// 2. Move token into home stretch or reach home (step 57)
  /// 3. Move token onto a safe star square
  /// 4. Release token from yard if rolled 6
  /// 5. Advance the farthest token
  LudoToken? selectBestAutoMove(int dice) {
    final movable = getMovableTokens(dice);
    if (movable.isEmpty) return null;
    if (movable.length == 1) return movable.first;

    // 1. Check for knockout move
    for (var token in movable) {
      int targetStep = token.isInYard ? 1 : token.step + dice;
      if (targetStep <= 51) {
        int simulatedGlobal = (token.color.startTrackIndex + (targetStep - 1)) % 52;
        if (!safeTrackIndices.contains(simulatedGlobal)) {
          bool canCapture = players.any((p) {
            if (p.color == token.color) return false;
            return p.tokens.any((t) => t.isOnTrack && t.globalTrackIndex == simulatedGlobal);
          });
          if (canCapture) return token;
        }
      }
    }

    // 2. Token reaching home (step 57)
    for (var token in movable) {
      if (!token.isInYard && token.step + dice == 57) {
        return token;
      }
    }

    // 3. Token entering home stretch (step > 51)
    for (var token in movable) {
      if (!token.isInYard && token.step <= 51 && (token.step + dice > 51)) {
        return token;
      }
    }

    // 4. Moving into a safe star square
    for (var token in movable) {
      int targetStep = token.isInYard ? 1 : token.step + dice;
      if (targetStep <= 51) {
        int simulatedGlobal = (token.color.startTrackIndex + (targetStep - 1)) % 52;
        if (safeTrackIndices.contains(simulatedGlobal)) {
          return token;
        }
      }
    }

    // 5. Release token from yard
    for (var token in movable) {
      if (token.isInYard) {
        return token;
      }
    }

    // 6. Default: Advance farthest token along the path
    movable.sort((a, b) => b.step.compareTo(a.step));
    return movable.first;
  }

  bool moveToken(LudoToken token, int dice) {
    if (!canMovableToken(token, dice)) return false;

    int newStep;
    if (token.isInYard) {
      newStep = 1; // enters main track
    } else {
      newStep = token.step + dice;
    }

    // Update token in player
    token.step = newStep;

    bool captured = false;

    // Check capture if on main track
    if (token.isOnTrack) {
      int globalIdx = token.globalTrackIndex!;
      if (!safeTrackIndices.contains(globalIdx)) {
        // Look for enemy tokens on the same square
        for (var p in players) {
          if (p.color == token.color) continue;
          for (var t in p.tokens) {
            if (t.isOnTrack && t.globalTrackIndex == globalIdx) {
              // Capture token! Send back to yard
              t.step = 0;
              captured = true;
            }
          }
        }
      }
    }

    // Check winner
    if (currentPlayer.hasWon) {
      winner = currentPlayer.color;
      state = LudoGameState.finished;
      return true;
    }

    // Turn transition rule:
    // Extra turn if rolled 6, captured enemy, or reached home (step 57)
    if (dice == 6 || captured || token.isHome) {
      state = LudoGameState.rolling;
    } else {
      nextTurn();
    }

    return true;
  }
}
