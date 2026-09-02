import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/alien.dart';
import 'components/alien_formation.dart';
import 'components/extra_ship.dart';
import 'components/laser.dart';
import 'components/player.dart';
import 'game_config.dart';

class SpaceInvadersGame extends FlameGame
    with HasCollisionDetection, DragCallbacks {
  SpaceInvadersGame()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: GameConfig.logicalWidth,
          height: GameConfig.logicalHeight,
        ),
      );

  static const List<String> spriteAssetNames = [
    'player.png',
    'green.png',
    'red.png',
    'yellow.png',
    'extra.png',
  ];
  static const Color sceneBackgroundColor = Color(0xFF10131A);

  late final Player player;

  @override
  Color backgroundColor() => sceneBackgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.position = Vector2(
      GameConfig.logicalWidth / 2,
      GameConfig.logicalHeight / 2,
    );
    await images.loadAll(spriteAssetNames);

    final alienSprites = {
      for (final variant in AlienVariant.values)
        variant: Sprite(images.fromCache(variant.assetName)),
    };
    player = Player(
      sprite: Sprite(images.fromCache('player.png')),
      onFire: _fireLaser,
    );
    world.addAll([
      AlienFormation(sprites: alienSprites),
      ExtraShip(sprite: Sprite(images.fromCache('extra.png'))),
      player,
    ]);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    event.handled = true;
    _movePlayerToCanvasX(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    event.handled = true;
    _movePlayerToCanvasX(event.canvasEndPosition);
  }

  void _movePlayerToCanvasX(Vector2 canvasPosition) {
    player.moveToX(camera.globalToLocal(canvasPosition).x);
  }

  void _fireLaser(Vector2 origin) {
    world.add(Laser(position: origin));
  }
}
