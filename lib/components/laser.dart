import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_config.dart';
import 'alien.dart';

class Laser extends PositionComponent with CollisionCallbacks {
  Laser({required Vector2 position, this.onAlienDestroyed})
    : super(
        position: position,
        size: Vector2(GameConfig.laserWidth, GameConfig.laserHeight),
        anchor: Anchor.bottomCenter,
      ) {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  /// Called exactly once when this laser destroys an alien.
  /// Null for ad-hoc lasers created directly in tests.
  final void Function(Alien alien)? onAlienDestroyed;

  bool _consumed = false;

  final Paint _paint = Paint()
    ..color = const Color(0xFFB8F4FF)
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

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
    if (_consumed || isRemoved) {
      return;
    }
    if (other is Alien) {
      if (other.destroyed || other.isRemoved) {
        return;
      }
      _consumed = true;
      other.destroyed = true;
      onAlienDestroyed?.call(other);
      other.removeFromParent();
      removeFromParent();
    }
  }
}
