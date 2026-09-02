import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_config.dart';
import 'alien.dart';

class Laser extends PositionComponent with CollisionCallbacks {
  Laser({required Vector2 position, required this.onAlienDestroyed})
    : super(
        position: position,
        size: Vector2(GameConfig.laserWidth, GameConfig.laserHeight),
        anchor: Anchor.bottomCenter,
      ) {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  final Paint _paint = Paint()
    ..color = const Color(0xFFB8F4FF)
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  final void Function() onAlienDestroyed;
  bool _hasHitAlien = false;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= GameConfig.laserSpeed * dt;
    if (position.y < 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Alien && !_hasHitAlien) {
      _hasHitAlien = true;
      other.removeFromParent();
      onAlienDestroyed();
      removeFromParent();
    }
  }
}
