import 'dart:ui'
    show Canvas, Color, Offset, Paint, PaintingStyle, Radius, Rect, RRect;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

class MainMenu extends PositionComponent with TapCallbacks {
  MainMenu({required this.onSelectLevel});

  final void Function() onSelectLevel;

  static const backgroundColor = Color(0xFF05070D);
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

  @override
  void onTapUp(TapUpEvent event) {
    final position = event.localPosition;
    if (_selectLevelButtonRect(
      size.x,
      size.y,
    ).contains(Offset(position.x, position.y))) {
      event.handled = true;
      onSelectLevel();
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
    _drawInvader(canvas, Offset(width / 2, height * 0.39), width * 0.24, _lime);
    _drawButton(
      canvas,
      _selectLevelButtonRect(width, height),
      'SELECT LEVEL',
      _cyan,
    );
    _drawButton(canvas, _quitButtonRect(width, height), 'QUIT', _pink);
    _drawFooter(canvas, width, height);
  }

  Rect _selectLevelButtonRect(double width, double height) {
    return Rect.fromCenter(
      center: Offset(width / 2, height * 0.61),
      width: width * 0.72,
      height: height * 0.105,
    );
  }

  Rect _quitButtonRect(double width, double height) {
    return Rect.fromCenter(
      center: Offset(width / 2, height * 0.75),
      width: width * 0.72,
      height: height * 0.105,
    );
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
        color: _lime,
        fontSize: 30,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
    ).render(
      canvas,
      'SPACE',
      Vector2(width / 2, height * 0.115),
      anchor: Anchor.center,
    );
    TextPaint(
      style: const TextStyle(
        color: Color(0xFFEAF6FF),
        fontSize: 30,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
    ).render(
      canvas,
      'INVADERS',
      Vector2(width / 2, height * 0.17),
      anchor: Anchor.center,
    );
    _stroke
      ..color = _cyan
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(width * 0.18, height * 0.22),
      Offset(width * 0.82, height * 0.22),
      _stroke,
    );
  }

  void _drawInvader(Canvas canvas, Offset center, double unit, Color color) {
    const pattern = ['.XX.', 'X..X', 'XXXX', 'X.XX', 'X..X'];
    final pixel = unit / 4;
    _fill.color = color;
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[y].length; x++) {
        if (pattern[y][x] == 'X') {
          canvas.drawRect(
            Rect.fromLTWH(
              center.dx + (x - 2) * pixel,
              center.dy + (y - 2.5) * pixel,
              pixel,
              pixel,
            ),
            _fill,
          );
        }
      }
    }
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
