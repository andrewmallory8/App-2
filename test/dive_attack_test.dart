import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_2/components/alien.dart';
import 'package:app_2/components/alien_formation.dart';
import 'package:app_2/components/laser.dart';
import 'package:app_2/components/player.dart';
import 'package:app_2/game_config.dart';
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

Future<Alien> forceDiver(WidgetTester tester, SpaceInvadersGame game) async {
  game.enemyAutoFireEnabled = false;
  expect(game.forceDiveAttack(), isTrue);
  await tester.runAsync(game.ready);
  await tester.pump();
  return game.world
      .descendants()
      .whereType<Alien>()
      .firstWhere((alien) => alien.isDiving);
}

void main() {
  testWidgets('forced dive detaches one alien but keeps the living count', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    game.diveAttackEnabled = false;
    final formation = game.world.firstChild<AlienFormation>()!;

    expect(game.forceDiveAttack(), isTrue);
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(game.activeDiverCount, 1);
    expect(formation.children.whereType<Alien>(), hasLength(14));
    // Detached divers still count as living for rage/fire pacing.
    expect(formation.livingAlienCount, 15);
  });

  testWidgets('dives are capped at the simultaneous-diver limit', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    game.diveAttackEnabled = false;

    for (var i = 0; i < GameConfig.maxSimultaneousDivers; i++) {
      expect(game.forceDiveAttack(), isTrue);
      await tester.runAsync(game.ready);
      await tester.pump();
    }
    expect(game.activeDiverCount, GameConfig.maxSimultaneousDivers);
    expect(game.forceDiveAttack(), isFalse);
  });

  testWidgets('dive scheduler launches a diver over time', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    expect(game.activeDiverCount, 0);

    game.update(GameConfig.diveAttackInterval);
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(game.activeDiverCount, 1);
  });

  testWidgets('diver falls and zig-zags left and right', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.diveAttackEnabled = false;
    final diver = await forceDiver(tester, game);

    final startY = diver.position.y;
    final xSamples = <double>[];
    // Drive the alien directly so player lasers cannot interfere.
    for (var i = 0; i < 12; i++) {
      diver.update(0.2);
      xSamples.add(diver.position.x);
    }

    expect(diver.position.y, greaterThan(startY));
    final spread = xSamples.reduce((a, b) => a > b ? a : b) -
        xSamples.reduce((a, b) => a < b ? a : b);
    expect(spread, greaterThan(20));
  });

  testWidgets('diver fires projectiles while flying downwards', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    final diver = await forceDiver(tester, game);
    // Park the diver away from the player's auto-fire lane so the only
    // new enemy projectile must come from the diver itself.
    diver.diveBaseX = 40;
    diver.position.x = 40;
    game.player.moveToX(GameConfig.logicalWidth - 40);
    expect(game.enemyProjectileCount, 0);

    game.update(GameConfig.diveFireInterval + 0.1);
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(diver.isDiving, isTrue);
    expect(game.enemyProjectileCount, 1);
  });

  testWidgets('diver wraps off the bottom and docks back into formation', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.diveAttackEnabled = false;
    final formation = game.world.firstChild<AlienFormation>()!;
    final diver = await forceDiver(tester, game);

    // Push the diver just above the exit line; one step wraps it.
    diver.position.y = GameConfig.logicalHeight + diver.size.y - 5;
    diver.update(0.2);
    expect(diver.isReturning, isTrue);
    expect(diver.position.y, lessThan(0));

    // Steer it next to its slot; one step docks it home.
    final target = formation.position + diver.homePosition!;
    diver.position.setValues(target.x + 5, target.y);
    diver.update(0.1);
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(diver.flightState, AlienFlightState.inFormation);
    expect(game.activeDiverCount, 0);
    expect(formation.children.whereType<Alien>(), hasLength(15));
  });

  testWidgets('diving alien can be shot for points', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    game.diveAttackEnabled = false;
    final diver = await forceDiver(tester, game);
    final points = diver.variant.points;
    final scoreBefore = game.score;

    game.world.add(
      Laser(
        position: Vector2(
          diver.position.x + diver.size.x / 2,
          diver.position.y + diver.size.y / 2,
        ),
        onAlienDestroyed: game.onAlienDestroyed,
      ),
    );
    await tester.runAsync(game.ready);

    game.update(0);
    await tester.runAsync(game.ready);

    expect(game.score, scoreBefore + points);
    expect(game.activeDiverCount, 0);
  });

  testWidgets('level two clears stray divers with the old formation', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    game.diveAttackEnabled = false;
    await forceDiver(tester, game);
    expect(game.activeDiverCount, 1);

    final aliens = game.world.descendants().whereType<Alien>().toList();
    for (final alien in aliens) {
      game.onAlienDestroyed(alien);
      alien.removeFromParent();
    }
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(game.activeDiverCount, 0);
    expect(game.world.descendants().whereType<Alien>(), hasLength(15));
    expect(game.world.firstChild<Player>(), isNotNull);
  });
}
