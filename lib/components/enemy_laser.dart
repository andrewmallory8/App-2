import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_config.dart';
import 'player.dart';

/// Downward-moving enemy projectile that damages the player on contact.
class EnemyLaser extends PositionComponent with CollisionCallbacks {
  EnemyLaser({required Vector2 position, this.onHitPlayer})
    : super(
        position: position,
        size: Vector2(
          GameConfig.enemyLaserWidth,
          GameConfig.enemyLaserHeight,
        ),
        anchor: Anchor.topCenter,
      ) {
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  /// Called at most once when this projectile hits the player.
  final void Function(EnemyLaser projectile)? onHitPlayer;

  bool _hasHit = false;

  /// Whether this projectile already registered its hit.
  bool get hasHit => _hasHit;

  final Paint _paint = Paint()
    ..color = const Color(0xFFFF6B6B)
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += GameConfig.enemyLaserSpeed * dt;
    if (position.y - size.y > GameConfig.logicalHeight) {
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
    if (_hasHit || isRemoved) {
      return;
    }
    if (other is Player) {
      if (other.isRemoved) {
        return;
      }
      _hasHit = true;
      onHitPlayer?.call(this);
    }
  }
}
