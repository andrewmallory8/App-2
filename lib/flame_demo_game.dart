import 'dart:ui' show Canvas, Color, Offset, Paint, PaintingStyle, Radius, Rect, RRect;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

/// Displays the main menu. Add navigation behavior to the buttons later.
class SpaceInvadersGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF05070D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(MainMenu(game: this));
  }
}

/// Retains compatibility with the original starter test and imports.
class FlameDemoGame extends SpaceInvadersGame {}

class MainMenu extends PositionComponent {
  MainMenu({required this.game});

  final SpaceInvadersGame game;
  static const _lime = Color(0xFFB7FF4A);
  static const _cyan = Color(0xFF69E9FF);
  static const _pink = Color(0xFFFF5CAA);
  static const _panel = Color(0xFF101B2A);
  final Paint _fill = Paint()..style = PaintingStyle.fill;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final List<Offset> _stars = List.generate(58, (index) => Offset(
        ((index * 37) % 101) / 100,
        ((index * 61 + 17) % 101) / 100,
      ));

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    if (width == 0 || height == 0) return;

    _drawStars(canvas, width, height);
    _drawTitle(canvas, width, height);
    _drawInvader(canvas, Offset(width / 2, height * .39), width * .24, _lime);
    _drawButton(canvas, Rect.fromCenter(center: Offset(width / 2, height * .61), width: width * .72, height: height * .105), 'SELECT LEVEL', _cyan);
    _drawButton(canvas, Rect.fromCenter(center: Offset(width / 2, height * .75), width: width * .72, height: height * .105), 'QUIT', _pink);
    _drawFooter(canvas, width, height);
  }

  void _drawStars(Canvas canvas, double width, double height) {
    _fill.color = const Color(0xFF8FAAC9);
    for (final star in _stars) {
      canvas.drawCircle(Offset(star.dx * width, star.dy * height), star.dx > .7 ? 1.5 : .8, _fill);
    }
  }

  void _drawTitle(Canvas canvas, double width, double height) {
    TextPaint(
      style: const TextStyle(color: _lime, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3),
    ).render(canvas, 'SPACE', Vector2(width / 2, height * .115), anchor: Anchor.center);
    TextPaint(
      style: const TextStyle(color: Color(0xFFEAF6FF), fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3),
    ).render(canvas, 'INVADERS', Vector2(width / 2, height * .17), anchor: Anchor.center);
    _stroke..color = _cyan..strokeWidth = 1;
    canvas.drawLine(Offset(width * .18, height * .22), Offset(width * .82, height * .22), _stroke);
  }

  void _drawInvader(Canvas canvas, Offset center, double unit, Color color) {
    const pattern = ['.XX.', 'X..X', 'XXXX', 'X.XX', 'X..X'];
    final pixel = unit / 4;
    _fill.color = color;
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[y].length; x++) {
        if (pattern[y][x] == 'X') {
          canvas.drawRect(Rect.fromLTWH(center.dx + (x - 2) * pixel, center.dy + (y - 2.5) * pixel, pixel, pixel), _fill);
        }
      }
    }
  }

  void _drawButton(Canvas canvas, Rect rect, String label, Color accent) {
    _fill.color = _panel;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), _fill);
    _stroke..color = accent..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), _stroke);
    TextPaint(
      style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2),
    ).render(canvas, label, Vector2(rect.center.dx, rect.center.dy), anchor: Anchor.center);
  }

  void _drawFooter(Canvas canvas, double width, double height) {
    TextPaint(
      style: const TextStyle(color: Color(0xFF7F95AD), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4),
    ).render(canvas, '© 2026 GALACTIC ARCADE', Vector2(width / 2, height * .93), anchor: Anchor.center);
  }
}
