import 'dart:ui';

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
      );

  final void Function(Vector2 origin) onFire;
  double _timeSinceLastShot = 0;

  void moveToX(double targetX) {
    position.x = targetX.clamp(
      GameConfig.playerHorizontalMargin + size.x / 2,
      GameConfig.logicalWidth - GameConfig.playerHorizontalMargin - size.x / 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastShot += dt;
    if (_timeSinceLastShot >= GameConfig.autoFireInterval) {
      _timeSinceLastShot %= GameConfig.autoFireInterval;
      onFire(Vector2(position.x, position.y - size.y / 2));
    }
  }
}
