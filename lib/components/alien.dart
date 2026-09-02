import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game_config.dart';

enum AlienVariant {
  yellow(assetName: 'yellow.png', points: 30),
  red(assetName: 'red.png', points: 20),
  green(assetName: 'green.png', points: 10);

  const AlienVariant({required this.assetName, required this.points});

  final String assetName;
  final int points;
}

class Alien extends SpriteComponent {
  Alien({
    required this.variant,
    required Sprite sprite,
    required Vector2 position,
  }) : super(
         sprite: sprite,
         position: position,
         size: Vector2(GameConfig.alienWidth, GameConfig.alienHeight),
         paint: Paint()
           ..filterQuality = FilterQuality.none
           ..isAntiAlias = false,
       ) {
    add(RectangleHitbox(isSolid: true, collisionType: CollisionType.passive));
  }

  final AlienVariant variant;
}
