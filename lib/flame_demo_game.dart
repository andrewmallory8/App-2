import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

class FlameDemoGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF10131A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(PlaceholderComponent());
  }
}

class PlaceholderComponent extends PositionComponent {
  PlaceholderComponent() : super(size: Vector2.all(160), anchor: Anchor.center);

  final Paint _paint = Paint()..color = const Color(0xFFFFA726);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = size / 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(24),
      ),
      _paint,
    );
  }
}
