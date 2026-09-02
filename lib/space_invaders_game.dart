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
import 'main_menu.dart';

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
  static const String menuRoute = '/menu';
  static const String playRoute = '/play';
  static const Color sceneBackgroundColor = Color(0xFF10131A);

  late final RouterComponent router;
  late final Player player;

  String get currentRouteName => router.currentRoute.name!;

  bool get _isPlaying => currentRouteName == playRoute;

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

    router = RouterComponent(
      initialRoute: menuRoute,
      routes: {
        menuRoute: Route(
          () => MainMenu(onSelectLevel: startGame),
          maintainState: false,
        ),
        playRoute: WorldRoute(_buildPlayWorld, maintainState: false),
      },
    );
    add(router);
  }

  void startGame() {
    router.pushReplacementNamed(playRoute);
  }

  World _buildPlayWorld() {
    final alienSprites = {
      for (final variant in AlienVariant.values)
        variant: Sprite(images.fromCache(variant.assetName)),
    };
    player = Player(
      sprite: Sprite(images.fromCache('player.png')),
      onFire: _fireLaser,
    );
    return World(
      children: [
        AlienFormation(sprites: alienSprites),
        ExtraShip(sprite: Sprite(images.fromCache('extra.png'))),
        player,
      ],
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_isPlaying) {
      return;
    }
    event.handled = true;
    _movePlayerToCanvasX(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isPlaying) {
      return;
    }
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
