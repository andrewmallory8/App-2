import 'package:flame/components.dart';

import '../game_config.dart';
import 'alien.dart';

class AlienFormation extends PositionComponent {
  AlienFormation({required Map<AlienVariant, Sprite> sprites})
    : super(
        position: Vector2(
          (GameConfig.logicalWidth - GameConfig.alienFormationWidth) / 2,
          GameConfig.alienFormationTop,
        ),
        size: Vector2(
          GameConfig.alienFormationWidth,
          GameConfig.alienFormationHeight,
        ),
      ) {
    for (final (row, variant) in AlienVariant.values.indexed) {
      for (var column = 0; column < GameConfig.alienColumns; column++) {
        add(
          Alien(
            variant: variant,
            sprite: sprites[variant]!,
            position: Vector2(
              column * (GameConfig.alienWidth + GameConfig.alienColumnGap),
              row * (GameConfig.alienHeight + GameConfig.alienRowGap),
            ),
          ),
        );
      }
    }
  }

  double _direction = 1;

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _direction * GameConfig.alienMarchSpeed * dt;

    final leftEdge = GameConfig.alienHorizontalMargin;
    final rightEdge =
        GameConfig.logicalWidth - GameConfig.alienHorizontalMargin - size.x;
    if (_direction < 0 && position.x <= leftEdge) {
      position.x = leftEdge;
      _reverseAndStepDown();
    } else if (_direction > 0 && position.x >= rightEdge) {
      position.x = rightEdge;
      _reverseAndStepDown();
    }
  }

  void _reverseAndStepDown() {
    _direction *= -1;
    position.y += GameConfig.alienStepDown;
  }
}
