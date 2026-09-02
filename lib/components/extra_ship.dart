import 'dart:ui';

import 'package:flame/components.dart';

import '../game_config.dart';

class ExtraShip extends SpriteComponent {
  ExtraShip({required Sprite sprite})
    : super(
        sprite: sprite,
        position: Vector2(GameConfig.extraShipInitialX, GameConfig.extraShipY),
        size: Vector2(GameConfig.extraShipWidth, GameConfig.extraShipHeight),
        anchor: Anchor.center,
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );

  double _pauseRemaining = 0;
  bool isVisible = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (_pauseRemaining > 0) {
      _pauseRemaining -= dt;
      if (_pauseRemaining <= 0) {
        _pauseRemaining = 0;
        position.x = -size.x / 2;
        isVisible = true;
      }
      return;
    }

    position.x += GameConfig.extraShipSpeed * dt;
    if (position.x - size.x / 2 > GameConfig.logicalWidth) {
      isVisible = false;
      _pauseRemaining = GameConfig.extraShipPause;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isVisible) {
      super.render(canvas);
    }
  }
}
