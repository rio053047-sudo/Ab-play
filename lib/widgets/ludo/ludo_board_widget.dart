import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ab_play/models/ludo/ludo_board_coordinates.dart';
import 'package:ab_play/models/ludo/ludo_color.dart';
import 'package:ab_play/models/ludo/ludo_engine.dart';
import 'package:ab_play/models/ludo/ludo_token.dart';
import 'package:ab_play/viewmodels/ludo_viewmodel.dart';

class PremiumLudoBoardPainter extends CustomPainter {
  final LudoViewModel viewModel;

  PremiumLudoBoardPainter(this.viewModel);

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / 15;

    // 1. Draw Board Outer Wooden / Metallic Frame
    _drawPremiumFrame(canvas, size);

    // 2. Draw Ivory Track Grid Background
    Rect innerBoardRect = Rect.fromLTWH(0, 0, size.width, size.height);
    Paint bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [Color(0xFFFFFBF0), Color(0xFFF3ECE0)],
      ).createShader(innerBoardRect);
    canvas.drawRect(innerBoardRect, bgPaint);

    // 3. Draw 4 Corner Base Quadrants (Yards) with Metallic Borders & Circles
    _drawPremiumYard(canvas, 0, 0, cellSize, LudoColor.green);
    _drawPremiumYard(canvas, 9 * cellSize, 0, cellSize, LudoColor.yellow);
    _drawPremiumYard(canvas, 0, 9 * cellSize, cellSize, LudoColor.red);
    _drawPremiumYard(canvas, 9 * cellSize, 9 * cellSize, cellSize, LudoColor.blue);

    // 4. Draw Track Grid Outline
    Paint gridLinePaint = Paint()
      ..color = const Color(0xFFD4C8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridLinePaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridLinePaint);
    }

    // 5. Draw Colored Victory Paths (Home Stretches) with Gradient Inlays
    _drawVictoryPath(canvas, cellSize, LudoColor.red, [
      const Point(1, 7),
      const Point(2, 7),
      const Point(3, 7),
      const Point(4, 7),
      const Point(5, 7),
      const Point(1, 8), // Red start square
    ]);

    _drawVictoryPath(canvas, cellSize, LudoColor.green, [
      const Point(7, 1),
      const Point(7, 2),
      const Point(7, 3),
      const Point(7, 4),
      const Point(7, 5),
      const Point(6, 1), // Green start square
    ]);

    _drawVictoryPath(canvas, cellSize, LudoColor.yellow, [
      const Point(13, 7),
      const Point(12, 7),
      const Point(11, 7),
      const Point(10, 7),
      const Point(9, 7),
      const Point(13, 6), // Yellow start square
    ]);

    _drawVictoryPath(canvas, cellSize, LudoColor.blue, [
      const Point(7, 13),
      const Point(7, 12),
      const Point(7, 11),
      const Point(7, 10),
      const Point(7, 9),
      const Point(8, 13), // Blue start square
    ]);

    // 6. Draw Center Home Convergence & Golden Triumph Emblem
    _drawCenterConvergence(canvas, cellSize);

    // 7. Draw 3D Embossed Star Safe Emblems
    _drawPremiumStars(canvas, cellSize);
  }

  void _drawPremiumFrame(Canvas canvas, Size size) {
    Rect fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    canvas.drawRect(fullRect, shadowPaint);
  }

  void _drawPremiumYard(Canvas canvas, double x, double y, double cellSize, LudoColor color) {
    Rect yardRect = Rect.fromLTWH(x, y, 6 * cellSize, 6 * cellSize);

    // Yard Outer Beveled Gradient
    Color baseCol = color.color;
    Paint outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseCol.withValues(alpha: 0.95),
          baseCol,
          Color.lerp(baseCol, Colors.black, 0.25)!,
        ],
      ).createShader(yardRect);
    canvas.drawRRect(RRect.fromRectAndRadius(yardRect, const Radius.circular(8)), outerPaint);

    // Gold Trim Inset
    Paint goldTrim = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(yardRect.deflate(cellSize * 0.15), const Radius.circular(6)),
      goldTrim,
    );

    // Yard Inner White / Ivory Tray
    Rect innerTrayRect = Rect.fromLTWH(x + cellSize, y + cellSize, 4 * cellSize, 4 * cellSize);
    Paint innerTrayPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFF7F3EB)],
      ).createShader(innerTrayRect);
    canvas.drawRRect(RRect.fromRectAndRadius(innerTrayRect, const Radius.circular(16)), innerTrayPaint);

    // Tray Inner Shadow / Border
    Paint innerBorder = Paint()
      ..color = const Color(0xFFD6C8B2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(innerTrayRect, const Radius.circular(16)), innerBorder);

    // Draw 4 circular token holding pedestals with metallic rings
    List<Offset> pedestals = [
      Offset(x + 2 * cellSize, y + 2 * cellSize),
      Offset(x + 4 * cellSize, y + 2 * cellSize),
      Offset(x + 2 * cellSize, y + 4 * cellSize),
      Offset(x + 4 * cellSize, y + 4 * cellSize),
    ];

    for (var pos in pedestals) {
      // Outer glow
      canvas.drawCircle(
        pos,
        cellSize * 0.65,
        Paint()..color = baseCol.withValues(alpha: 0.15),
      );
      // Ring
      canvas.drawCircle(
        pos,
        cellSize * 0.55,
        Paint()
          ..color = baseCol.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Pedestal base
      canvas.drawCircle(
        pos,
        cellSize * 0.45,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawVictoryPath(
      Canvas canvas, double cellSize, LudoColor color, List<Point<int>> points) {
    Color primaryColor = color.color;

    for (var pt in points) {
      Rect cellRect = Rect.fromLTWH(pt.x * cellSize, pt.y * cellSize, cellSize, cellSize);

      Paint pathPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.9),
            primaryColor,
            Color.lerp(primaryColor, Colors.black, 0.15)!,
          ],
        ).createShader(cellRect);

      canvas.drawRect(cellRect, pathPaint);

      // Subtle inner glow
      Paint highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(cellRect.deflate(1.5), highlightPaint);
    }
  }

  void _drawCenterConvergence(Canvas canvas, double cellSize) {
    double left = 6 * cellSize;
    double top = 6 * cellSize;
    double right = 9 * cellSize;
    double bottom = 9 * cellSize;
    double centerX = 7.5 * cellSize;
    double centerY = 7.5 * cellSize;

    // Green Triangle (Top)
    Path pathG = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathG, Paint()..color = LudoColor.green.color);

    // Yellow Triangle (Right)
    Path pathY = Path()
      ..moveTo(right, top)
      ..lineTo(right, bottom)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathY, Paint()..color = LudoColor.yellow.color);

    // Blue Triangle (Bottom)
    Path pathB = Path()
      ..moveTo(right, bottom)
      ..lineTo(left, bottom)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathB, Paint()..color = LudoColor.blue.color);

    // Red Triangle (Left)
    Path pathR = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top)
      ..lineTo(centerX, centerY)
      ..close();
    canvas.drawPath(pathR, Paint()..color = LudoColor.red.color);

    // Gold Center Triumph Emblem
    Paint goldEmblemBg = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFECB3), Color(0xFFFFC107), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: cellSize * 0.9));
    canvas.drawCircle(Offset(centerX, centerY), cellSize * 0.75, goldEmblemBg);

    Paint goldBorder = Paint()
      ..color = const Color(0xFFB78103)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(centerX, centerY), cellSize * 0.75, goldBorder);

    // Center Gold Star
    _drawStarIcon(
      canvas,
      Offset(centerX, centerY),
      cellSize * 0.45,
      Paint()..color = const Color(0xFFFFF8E1),
    );
  }

  void _drawPremiumStars(Canvas canvas, double cellSize) {
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

    for (var pt in safeSpots) {
      double cx = (pt.x + 0.5) * cellSize;
      double cy = (pt.y + 0.5) * cellSize;

      // Drop shadow for star badge
      Paint starShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      _drawStarIcon(canvas, Offset(cx + 1, cy + 1), cellSize * 0.35, starShadow);

      // Gold Star Body
      Paint starPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFEE58),
            const Color(0xFFFDD835),
            Colors.amber.shade800,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: cellSize * 0.35));

      _drawStarIcon(canvas, Offset(cx, cy), cellSize * 0.34, starPaint);

      // Star Border
      Paint borderPaint = Paint()
        ..color = const Color(0xFFB78103)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      _drawStarIcon(canvas, Offset(cx, cy), cellSize * 0.34, borderPaint);
    }
  }

  void _drawStarIcon(Canvas canvas, Offset center, double radius, Paint paint) {
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
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A3425), Color(0xFF2C1E16)],
          ),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Color(0x33FFD700),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cellSize = constraints.maxWidth / 15;

              return Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: PremiumLudoBoardPainter(viewModel),
                  ),
                  // Render 3D Tokens
                  ...viewModel.engine.players.expand((player) {
                    return player.tokens.map((token) {
                      final pos = LudoBoardCoordinates.getGridPosition(token);
                      bool isMovable = viewModel.engine.canMovableToken(
                              token, viewModel.engine.currentDiceValue ?? 0) &&
                          viewModel.engine.state == LudoGameState.selectingToken;

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        left: pos.x * cellSize + (cellSize * 0.08),
                        top: pos.y * cellSize + (cellSize * 0.08),
                        width: cellSize * 0.84,
                        height: cellSize * 0.84,
                        child: GestureDetector(
                          onTap: () {
                            if (isMovable) {
                              viewModel.selectToken(token);
                            }
                          },
                          child: _build3DToken(token, cellSize * 0.84, isMovable),
                        ),
                      );
                    });
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _build3DToken(LudoToken token, double size, bool isMovable) {
    Color base = token.color.color;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isMovable ? size * 1.05 : size * 0.95,
        height: isMovable ? size * 1.05 : size * 0.95,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: isMovable ? 10 : 5,
              offset: const Offset(2, 4),
            ),
            if (isMovable)
              const BoxShadow(
                color: Color(0xFFFFD700),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 0.8,
              colors: [
                Color.lerp(base, Colors.white, 0.6)!,
                base,
                Color.lerp(base, Colors.black, 0.35)!,
              ],
            ),
            border: Border.all(
              color: isMovable ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.9),
              width: isMovable ? 2.5 : 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.2),
                  colors: [
                    Colors.white,
                    Color.lerp(Colors.white, base, 0.4)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
