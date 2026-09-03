import 'package:flame/components.dart';

import '../game_config.dart';
import 'alien.dart';

class AlienFormation extends PositionComponent {
  AlienFormation({
    required Map<AlienVariant, Sprite> sprites,
    this.speedMultiplier = 1,
  })
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
        final alien = Alien(
          variant: variant,
          sprite: sprites[variant]!,
          position: Vector2(
            column * (GameConfig.alienWidth + GameConfig.alienColumnGap),
            row * (GameConfig.alienHeight + GameConfig.alienRowGap),
          ),
        );
        _roster.add(alien);
        add(alien);
      }
    }
  }

  double _direction = 1;
  final double speedMultiplier;

  /// Every alien spawned for this formation, including divers currently
  /// reparented into the world. [children] alone is not enough once
  /// divers detach, so the living count tracks this roster instead.
  final List<Alien> _roster = [];

  /// All aliens spawned for this formation, living or destroyed.
  List<Alien> get roster => List.unmodifiable(_roster);

  int get livingAlienCount =>
      _roster.where((alien) => !alien.destroyed).length;

  int get totalAlienCount =>
      AlienVariant.values.length * GameConfig.alienColumns;

  @override
  void update(double dt) {
    super.update(dt);
    final defeatedRatio = 1 - livingAlienCount / totalAlienCount;
    final rageMultiplier =
        1 + defeatedRatio * GameConfig.alienRageSpeedBonus;
    position.x +=
        _direction *
        GameConfig.alienMarchSpeed *
        speedMultiplier *
        rageMultiplier *
        dt;

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
