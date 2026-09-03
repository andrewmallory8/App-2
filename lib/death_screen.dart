import 'dart:ui'
    show Canvas, Color, Offset, Paint, PaintingStyle, Radius, Rect, RRect;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

/// Flame-rendered death screen matching the [MainMenu] visual style.
class DeathScreen extends PositionComponent with TapCallbacks {
  DeathScreen({
    required this.score,
    required this.onRestart,
    required this.onMainMenu,
  });

  final int score;
  final void Function() onRestart;
  final void Function() onMainMenu;

  static const backgroundColor = Color(0xFF05070D);
  static const _red = Color(0xFFFF5C5C);
  static const _lime = Color(0xFFB7FF4A);
  static const _cyan = Color(0xFF69E9FF);
  static const _pink = Color(0xFFFF5CAA);
  static const _panel = Color(0xFF101B2A);

  final Paint _fill = Paint()..style = PaintingStyle.fill;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final List<Offset> _stars = List.generate(
    58,
    (index) =>
        Offset(((index * 37) % 101) / 100, ((index * 61 + 17) % 101) / 100),
  );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  Rect restartButtonRect(double width, double height) {
    return Rect.fromCenter(
      center: Offset(width / 2, height * 0.61),
      width: width * 0.72,
      height: height * 0.105,
    );
  }

  Rect mainMenuButtonRect(double width, double height) {
    return Rect.fromCenter(
      center: Offset(width / 2, height * 0.75),
      width: width * 0.72,
      height: height * 0.105,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    final position = event.localPosition;
    final offset = Offset(position.x, position.y);
    if (restartButtonRect(size.x, size.y).contains(offset)) {
      event.handled = true;
      onRestart();
    } else if (mainMenuButtonRect(size.x, size.y).contains(offset)) {
      event.handled = true;
      onMainMenu();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    if (width == 0 || height == 0) {
      return;
    }

    _fill.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), _fill);
    _drawStars(canvas, width, height);
    _drawTitle(canvas, width, height);
    _drawScore(canvas, width, height);
    _drawButton(canvas, restartButtonRect(width, height), 'RESTART', _cyan);
    _drawButton(
      canvas,
      mainMenuButtonRect(width, height),
      'MAIN MENU',
      _pink,
    );
    _drawFooter(canvas, width, height);
  }

  void _drawStars(Canvas canvas, double width, double height) {
    _fill.color = const Color(0xFF8FAAC9);
    for (final star in _stars) {
      canvas.drawCircle(
        Offset(star.dx * width, star.dy * height),
        star.dx > 0.7 ? 1.5 : 0.8,
        _fill,
      );
    }
  }

  void _drawTitle(Canvas canvas, double width, double height) {
    TextPaint(
      style: const TextStyle(
        color: _red,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
    ).render(
      canvas,
      'GAME OVER',
      Vector2(width / 2, height * 0.20),
      anchor: Anchor.center,
    );
    _stroke
      ..color = _cyan
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(width * 0.18, height * 0.26),
      Offset(width * 0.82, height * 0.26),
      _stroke,
    );
  }

  void _drawScore(Canvas canvas, double width, double height) {
    TextPaint(
      style: const TextStyle(
        color: _lime,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    ).render(
      canvas,
      'SCORE $score',
      Vector2(width / 2, height * 0.38),
      anchor: Anchor.center,
    );
    TextPaint(
      style: const TextStyle(
        color: Color(0xFF7F95AD),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    ).render(
      canvas,
      'THE INVADERS PREVAIL',
      Vector2(width / 2, height * 0.45),
      anchor: Anchor.center,
    );
  }

  void _drawButton(Canvas canvas, Rect rect, String label, Color accent) {
    _fill.color = _panel;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      _fill,
    );
    _stroke
      ..color = accent
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      _stroke,
    );
    TextPaint(
      style: TextStyle(
        color: accent,
        fontSize: 17,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    ).render(
      canvas,
      label,
      Vector2(rect.center.dx, rect.center.dy),
      anchor: Anchor.center,
    );
  }

  void _drawFooter(Canvas canvas, double width, double height) {
    TextPaint(
      style: const TextStyle(
        color: Color(0xFF7F95AD),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    ).render(
      canvas,
      '© 2026 GALACTIC ARCADE',
      Vector2(width / 2, height * 0.93),
      anchor: Anchor.center,
    );
  }
}
