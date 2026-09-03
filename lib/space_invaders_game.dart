import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

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
  int _level = 1;
  int _aliensDefeated = 0;
  TextComponent? _levelLabel;
  AlienFormation? _alienFormation;
  Map<AlienVariant, Sprite>? _alienSprites;

  static int get _aliensNeededForLevelTwo =>
      GameConfig.alienColumns * AlienVariant.values.length;

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
    _level = 1;
    _aliensDefeated = 0;
    router.pushReplacementNamed(playRoute);
  }

  World _buildPlayWorld() {
    _level = 1;
    final alienSprites = <AlienVariant, Sprite>{
      for (final variant in AlienVariant.values)
        variant: Sprite(images.fromCache(variant.assetName)),
    };
    _alienSprites = alienSprites;
    player = Player(
      sprite: Sprite(images.fromCache('player.png')),
      onFire: _fireLaser,
    );
    final levelLabel = TextComponent(
      text: 'LEVEL $_level',
      position: Vector2(GameConfig.logicalWidth / 2, 18),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFEAF6FF),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
    _levelLabel = levelLabel;
    final formation = AlienFormation(sprites: alienSprites);
    _alienFormation = formation;
    return World(
      children: [
        levelLabel,
        formation,
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
    world.add(Laser(position: origin, onAlienDestroyed: _onAlienDestroyed));
  }

  void _onAlienDestroyed() {
    if (_level != 1) {
      return;
    }
    _aliensDefeated++;
    if (_aliensDefeated >= _aliensNeededForLevelTwo) {
      _startLevelTwo();
    }
  }

  void _startLevelTwo() {
    _level = 2;
    _levelLabel?.text = 'LEVEL 2';
    _alienFormation?.removeFromParent();
    final sprites = _alienSprites;
    if (sprites != null) {
      world.add(AlienFormation(sprites: sprites, speedMultiplier: 1.5));
    }
  }

}
