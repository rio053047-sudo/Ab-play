import 'dart:math';
import 'ludo_color.dart';
import 'ludo_token.dart';

class LudoBoardCoordinates {
  // 52 main track grid positions (X, Y)
  static const List<Point<int>> mainTrack = [
    // Red Start area (Bottom-Left exit) -> X=1, Y=8
    Point(1, 8), Point(2, 8), Point(3, 8), Point(4, 8), Point(5, 8),
    Point(6, 9), Point(6, 10), Point(6, 11), Point(6, 12), Point(6, 13), Point(6, 14),
    Point(7, 14), Point(8, 14), // Blue Start at (8, 13)
    Point(8, 13), Point(8, 12), Point(8, 11), Point(8, 10), Point(8, 9),
    Point(9, 8), Point(10, 8), Point(11, 8), Point(12, 8), Point(13, 8), Point(14, 8),
    Point(14, 7), Point(14, 6), // Yellow Start at (13, 6)
    Point(13, 6), Point(12, 6), Point(11, 6), Point(10, 6), Point(9, 6),
    Point(8, 5), Point(8, 4), Point(8, 3), Point(8, 2), Point(8, 1), Point(8, 0),
    Point(7, 0), Point(6, 0), // Green Start at (6, 1)
    Point(6, 1), Point(6, 2), Point(6, 3), Point(6, 4), Point(6, 5),
    Point(5, 6), Point(4, 6), Point(3, 6), Point(2, 6), Point(1, 6), Point(0, 6),
    Point(0, 7), Point(0, 8),
  ];

  static Point<int> getGridPosition(LudoToken token) {
    if (token.isInYard) {
      return getYardPosition(token.color, token.id);
    }

    if (token.isHome) {
      return const Point(7, 7); // Center
    }

    if (token.isInHomeStretch) {
      int homeStep = token.step - 51; // 1..5
      switch (token.color) {
        case LudoColor.red:
          return Point(homeStep, 7);
        case LudoColor.green:
          return Point(7, homeStep);
        case LudoColor.yellow:
          return Point(14 - homeStep, 7);
        case LudoColor.blue:
          return Point(7, 14 - homeStep);
      }
    }

    // On main track
    int globalIdx = token.globalTrackIndex!;
    return mainTrack[globalIdx % 52];
  }

  static Point<int> getYardPosition(LudoColor color, int tokenId) {
    // 4 positions inside yard
    final offsets = [
      const Point(1.5, 1.5),
      const Point(3.5, 1.5),
      const Point(1.5, 3.5),
      const Point(3.5, 3.5),
    ];

    double baseX = 0;
    double baseY = 0;

    switch (color) {
      case LudoColor.green: // Top-Left
        baseX = 0;
        baseY = 0;
        break;
      case LudoColor.yellow: // Top-Right
        baseX = 9;
        baseY = 0;
        break;
      case LudoColor.red: // Bottom-Left
        baseX = 0;
        baseY = 9;
        break;
      case LudoColor.blue: // Bottom-Right
        baseX = 9;
        baseY = 9;
        break;
    }

    return Point(
      (baseX + offsets[tokenId].x).floor(),
      (baseY + offsets[tokenId].y).floor(),
    );
  }
}
