import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_config.dart';

class Player extends SpriteComponent {
  Player({required Sprite sprite, required this.onFire})
    : super(
        sprite: sprite,
        position: Vector2(
          GameConfig.logicalWidth / 2,
          GameConfig.logicalHeight -
              GameConfig.playerBottomMargin -
              GameConfig.playerHeight / 2,
        ),
        size: Vector2(GameConfig.playerWidth, GameConfig.playerHeight),
        anchor: Anchor.center,
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      ) {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  final void Function(Vector2 origin) onFire;
  double _timeSinceLastShot = 0;

  /// Whether the ship is in its post-hit invulnerability window.
  /// Driven by the game; while true the ship blinks via [isVisible].
  bool isInvulnerable = false;
  double _blinkElapsed = 0;

  /// Blink state: false phases skip rendering to flash on and off.
  bool isVisible = true;

  /// Horizontal start position for a fresh life.
  static double get startX => GameConfig.logicalWidth / 2;

  void moveToX(double targetX) {
    position.x = targetX.clamp(
      GameConfig.playerHorizontalMargin + size.x / 2,
      GameConfig.logicalWidth - GameConfig.playerHorizontalMargin - size.x / 2,
    );
  }

  /// Enter or leave the invulnerability blink. Transition-aware so the game
  /// can sync it every frame without restarting the blink rhythm.
  void setInvulnerable(bool value) {
    if (isInvulnerable == value) {
      return;
    }
    isInvulnerable = value;
    _blinkElapsed = 0;
    // Vanish immediately on hit so the loss reads instantly.
    isVisible = !value;
  }

  /// Reset to the starting horizontal position after losing a life.
  void resetToStart() {
    position.x = startX;
    _timeSinceLastShot = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isInvulnerable) {
      _blinkElapsed += dt;
      final phase =
          (_blinkElapsed / GameConfig.invulnerabilityFlashInterval).floor() % 2;
      isVisible = phase == 0;
    } else {
      isVisible = true;
    }
    _timeSinceLastShot += dt;
    if (_timeSinceLastShot >= GameConfig.autoFireInterval) {
      _timeSinceLastShot %= GameConfig.autoFireInterval;
      onFire(Vector2(position.x, position.y - size.y / 2));
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) {
      return;
    }
    super.render(canvas);
  }
}
