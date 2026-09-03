import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:app_2/components/alien.dart';
import 'package:app_2/components/alien_formation.dart';
import 'package:app_2/components/extra_ship.dart';
import 'package:app_2/components/laser.dart';
import 'package:app_2/components/player.dart';
import 'package:app_2/game_config.dart';
import 'package:app_2/main.dart';
import 'package:app_2/main_menu.dart';
import 'package:app_2/space_invaders_game.dart';

Future<void> pumpGame(WidgetTester tester, SpaceInvadersGame game) async {
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump();
  await tester.runAsync(() async {
    await game.loaded;
    await game.ready();
  });
  await tester.pump();
  await tester.pump();
}

Future<void> pumpPlayingGame(
  WidgetTester tester,
  SpaceInvadersGame game,
) async {
  await pumpGame(tester, game);
  game.startGame();
  await tester.runAsync(game.ready);
  await tester.pump();
  await tester.pump();
}

const expectedPlayerSafetyMargin = 12.0;

void main() {
  testWidgets('app keeps the game inside the device safe area', (tester) async {
    await tester.pumpWidget(const SpaceInvadersApp());
    await tester.pump();

    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(GameWidget<SpaceInvadersGame>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('select level routes from the menu to the game scene', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(
      const Size(GameConfig.logicalWidth, GameConfig.logicalHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = SpaceInvadersGame();
    await pumpGame(tester, game);

    expect(game.currentRouteName, SpaceInvadersGame.menuRoute);
    expect(game.descendants().whereType<MainMenu>(), hasLength(1));
    expect(game.world.descendants().whereType<Alien>(), isEmpty);

    await tester.tapAt(
      const Offset(
        GameConfig.logicalWidth / 2,
        GameConfig.logicalHeight * 0.61,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(game.currentRouteName, SpaceInvadersGame.playRoute);
    expect(game.descendants().whereType<MainMenu>(), isEmpty);
    expect(game.world.descendants().whereType<Alien>(), hasLength(15));
  });

  testWidgets('loads every sprite asset into the image cache', (tester) async {
    final game = SpaceInvadersGame();

    await pumpGame(tester, game);

    expect(tester.takeException(), isNull);
    for (final assetName in SpaceInvadersGame.spriteAssetNames) {
      expect(
        game.images.containsKey(assetName),
        isTrue,
        reason: '$assetName should be preloaded',
      );
    }
  });

  testWidgets('populates the classic formation with 15 aliens', (tester) async {
    final game = SpaceInvadersGame();

    await pumpPlayingGame(tester, game);

    final aliens = game.world.descendants().whereType<Alien>();
    expect(aliens, hasLength(15));
  });

  testWidgets('alien formation marches, reverses, and steps down', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    final formation = game.world.firstChild<AlienFormation>()!;

    final startingX = formation.position.x;
    game.update(0.25);
    expect(formation.position.x, greaterThan(startingX));

    formation.position.x = GameConfig.logicalWidth - formation.size.x;
    final startingY = formation.position.y;
    game.update(0.1);
    expect(formation.position.y, greaterThan(startingY));

    final rightEdgeX = formation.position.x;
    game.update(0.25);
    expect(formation.position.x, lessThan(rightEdgeX));
  });

  testWidgets('player movement keeps a horizontal safety margin', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    final player = game.world.firstChild<Player>()!;

    player.moveToX(-100);
    expect(player.position.x, expectedPlayerSafetyMargin + player.size.x / 2);

    player.moveToX(GameConfig.logicalWidth + 100);
    expect(
      player.position.x,
      GameConfig.logicalWidth - expectedPlayerSafetyMargin - player.size.x / 2,
    );
  });

  testWidgets('horizontal drag moves the player and clamps at both edges', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(
      const Size(GameConfig.logicalWidth, GameConfig.logicalHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    final player = game.world.firstChild<Player>()!;

    await tester.dragFrom(
      Offset(GameConfig.logicalWidth / 2, player.position.y),
      const Offset(-500, 0),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(player.position.x, expectedPlayerSafetyMargin + player.size.x / 2);

    await tester.dragFrom(
      Offset(GameConfig.logicalWidth / 2, player.position.y),
      const Offset(500, 0),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      player.position.x,
      GameConfig.logicalWidth - expectedPlayerSafetyMargin - player.size.x / 2,
    );
  });

  testWidgets('player auto-fire spawns an upward-moving laser', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);

    game.update(GameConfig.autoFireInterval);
    await tester.runAsync(game.ready);
    final laser = game.world.descendants().whereType<Laser>().single;
    final startingY = laser.position.y;

    game.update(0.1);
    expect(laser.position.y, lessThan(startingY));
  });

  testWidgets('laser despawns after leaving the top of the playfield', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.update(GameConfig.autoFireInterval);
    await tester.runAsync(game.ready);
    final laser = game.world.descendants().whereType<Laser>().single;

    laser.position.y = 0;
    game.update(0.1);
    await tester.runAsync(game.ready);

    expect(game.world.descendants().whereType<Laser>(), isEmpty);
  });

  testWidgets('laser collision removes the laser and the alien', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    final alien = game.world.descendants().whereType<Alien>().first;
    final laser = Laser(
      position: alien.absoluteCenter,
      onAlienDestroyed: (alien) {},
    );
    game.world.add(laser);
    await tester.runAsync(game.ready);

    game.update(0);
    await tester.runAsync(game.ready);

    expect(game.world.descendants().whereType<Alien>(), hasLength(14));
    expect(game.world.descendants().whereType<Laser>(), isEmpty);
  });

  testWidgets('extra ship crosses the screen and restarts after a pause', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    final extraShip = game.world.firstChild<ExtraShip>()!;

    final startingX = extraShip.position.x;
    game.update(0.25);
    expect(extraShip.position.x, greaterThan(startingX));

    extraShip.position.x = GameConfig.logicalWidth + extraShip.size.x;
    game.update(0);
    expect(extraShip.isVisible, isFalse);

    game.update(GameConfig.extraShipPause);
    expect(extraShip.isVisible, isTrue);
    expect(extraShip.position.x, lessThanOrEqualTo(0));
  });
}
