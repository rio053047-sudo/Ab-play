import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ab_play/models/ludo/ludo_board_coordinates.dart';
import 'package:ab_play/models/ludo/ludo_color.dart';
import 'package:ab_play/models/ludo/ludo_engine.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';

class LudoBoardPainter extends CustomPainter {
  final LudoViewModel viewModel;

  LudoBoardPainter(this.viewModel);

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / 15;

    // Paint background
    Paint bgPaint = Paint()..color = const Color(0xFFFAFAFA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Yards
    _drawYard(canvas, 0, 0, cellSize, LudoColor.green);
    _drawYard(canvas, 9 * cellSize, 0, cellSize, LudoColor.yellow);
    _drawYard(canvas, 0, 9 * cellSize, cellSize, LudoColor.red);
    _drawYard(canvas, 9 * cellSize, 9 * cellSize, cellSize, LudoColor.blue);

    // Draw Grid Lines
    Paint linePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        linePaint,
      );
    }

    // Color Home Stretches and Special Paths
    _drawColoredPath(canvas, cellSize, LudoColor.red, [
      const Point(1, 7),
      const Point(2, 7),
      const Point(3, 7),
      const Point(4, 7),
      const Point(5, 7),
      const Point(1, 8), // Start spot
    ]);

    _drawColoredPath(canvas, cellSize, LudoColor.green, [
      const Point(7, 1),
      const Point(7, 2),
      const Point(7, 3),
      const Point(7, 4),
      const Point(7, 5),
      const Point(6, 1), // Start spot
    ]);

    _drawColoredPath(canvas, cellSize, LudoColor.yellow, [
      const Point(13, 7),
      const Point(12, 7),
      const Point(11, 7),
      const Point(10, 7),
      const Point(9, 7),
      const Point(13, 6), // Start spot
    ]);

    _drawColoredPath(canvas, cellSize, LudoColor.blue, [
      const Point(7, 13),
      const Point(7, 12),
      const Point(7, 11),
      const Point(7, 10),
      const Point(7, 9),
      const Point(8, 13), // Start spot
    ]);

    // Draw Center Home Triangle
    _drawCenterHome(canvas, cellSize);

    // Draw Safe Star Spots
    _drawStars(canvas, cellSize);
  }

  void _drawYard(
      Canvas canvas, double x, double y, double cellSize, LudoColor color) {
    Paint yardPaint = Paint()..color = color.color;
    canvas.drawRect(
        Rect.fromLTWH(x, y, 6 * cellSize, 6 * cellSize), yardPaint);

    Paint innerPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(
            x + cellSize, y + cellSize, 4 * cellSize, 4 * cellSize),
        innerPaint);
  }

  void _drawColoredPath(Canvas canvas, double cellSize, LudoColor color,
      List<Point<int>> points) {
    Paint p = Paint()..color = color.color;
    for (var pt in points) {
      canvas.drawRect(
        Rect.fromLTWH(
            pt.x * cellSize, pt.y * cellSize, cellSize, cellSize),
        p,
      );
    }
  }

  void _drawCenterHome(Canvas canvas, double cellSize) {
    double left = 6 * cellSize;
    double top = 6 * cellSize;
    double right = 9 * cellSize;
    double bottom = 9 * cellSize;
    double centerX = 7.5 * cellSize;
    double centerY = 7.5 * cellSize;

    // Green (Top)
    Path pathG = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathG, Paint()..color = LudoColor.green.color);

    // Yellow (Right)
    Path pathY = Path()
      ..moveTo(right, top)
      ..lineTo(right, bottom)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathY, Paint()..color = LudoColor.yellow.color);

    // Blue (Bottom)
    Path pathB = Path()
      ..moveTo(right, bottom)
      ..lineTo(left, bottom)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathB, Paint()..color = LudoColor.blue.color);

    // Red (Left)
    Path pathR = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathR, Paint()..color = LudoColor.red.color);
  }

  void _drawStars(Canvas canvas, double cellSize) {
    List<Point<int>> safeSpots = [
      const Point(1, 8),
      const Point(6, 1),
      const Point(13, 6),
      const Point(8, 13),
      const Point(8, 2),
      const Point(12, 8),
      const Point(6, 12),
      const Point(2, 6),
    ];

    Paint starPaint = Paint()
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.fill;

    for (var pt in safeSpots) {
      double cx = (pt.x + 0.5) * cellSize;
      double cy = (pt.y + 0.5) * cellSize;
      _drawStarIcon(canvas, Offset(cx, cy), cellSize * 0.3, starPaint);
    }
  }

  void _drawStarIcon(
      Canvas canvas, Offset center, double radius, Paint paint) {
    Path path = Path();
    int points = 5;
    double halfAngle = pi / points;

    for (int i = 0; i < 2 * points; i++) {
      double r = (i % 2 == 0) ? radius : radius / 2;
      double x = center.dx + r * cos(i * halfAngle - pi / 2);
      double y = center.dy + r * sin(i * halfAngle - pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LudoBoardWidget extends StatelessWidget {
  final LudoViewModel viewModel;

  const LudoBoardWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double cellSize = constraints.maxWidth / 15;

            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: LudoBoardPainter(viewModel),
                ),
                // Render Tokens
                ...viewModel.engine.players.expand((player) {
                  return player.tokens.map((token) {
                    final pos = LudoBoardCoordinates.getGridPosition(token);
                    bool isMovable =
                        viewModel.engine.canMovableToken(token, viewModel.engine.currentDiceValue ?? 0) &&
                            viewModel.engine.state == LudoGameState.selectingToken;

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: pos.x * cellSize + (cellSize * 0.1),
                      top: pos.y * cellSize + (cellSize * 0.1),
                      width: cellSize * 0.8,
                      height: cellSize * 0.8,
                      child: GestureDetector(
                        onTap: () {
                          if (isMovable) {
                            viewModel.selectToken(token);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: token.color.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMovable ? Colors.amber : Colors.white,
                              width: isMovable ? 3.0 : 1.5,
                            ),
                            boxShadow: isMovable
                                ? [
                                    const BoxShadow(
                                      color: Colors.amber,
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [
                                    const BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                    )
                                  ],
                          ),
                          child: Center(
                            child: Container(
                              width: cellSize * 0.3,
                              height: cellSize * 0.3,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
