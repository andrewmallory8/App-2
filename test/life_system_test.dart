import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:app_2/components/alien.dart';
import 'package:app_2/components/alien_formation.dart';
import 'package:app_2/components/enemy_laser.dart';
import 'package:app_2/components/hud.dart';
import 'package:app_2/components/laser.dart';
import 'package:app_2/components/player.dart';
import 'package:app_2/death_screen.dart';
import 'package:app_2/game_config.dart';
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

Future<void> settleRoute(WidgetTester tester, SpaceInvadersGame game) async {
  await tester.runAsync(game.ready);
  await tester.pump();
  await tester.pump();
}

Future<void> completeLevelOne(
  WidgetTester tester,
  SpaceInvadersGame game,
) async {
  final aliens = game.world.descendants().whereType<Alien>().toList();
  for (final alien in aliens) {
    game.onAlienDestroyed(alien);
    alien.removeFromParent();
  }
  await tester.runAsync(game.ready);
  await tester.pump();
}

void main() {
  testWidgets('new play session starts with 3 lives and score 0', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);

    expect(game.lives, GameConfig.initialLives);
    expect(game.lives, 3);
    expect(game.score, 0);
    expect(game.isGameOver, isFalse);
  });

  testWidgets('HUD displays lives and score', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    final hud = game.world.firstChild<Hud>()!;
    await tester.runAsync(game.ready);
    game.update(0);
    expect(hud.livesLabel, contains('3'));
    expect(hud.livesLabel, contains('LIVES'));
    expect(hud.scoreLabel, contains('SCORE'));
    expect(hud.scoreLabel, contains('0'));

    // HUD follows state changes.
    game.score = 40;
    game.update(0);
    expect(hud.scoreLabel, contains('40'));
  });

  testWidgets('laser collision removes one alien and scores its points', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    final alien = game.world.descendants().whereType<Alien>().first;
    final points = alien.variant.points;
    final scoreBefore = game.score;
    final laser = Laser(
      position: alien.absoluteCenter.clone(),
      onAlienDestroyed: game.onAlienDestroyed,
    );
    game.world.add(laser);
    await tester.runAsync(game.ready);

    game.update(0);
    await tester.runAsync(game.ready);

    expect(game.world.descendants().whereType<Alien>(), hasLength(14));
    expect(game.world.descendants().whereType<Laser>(), isEmpty);
    expect(game.score, scoreBefore + points);

    // Same alien must not score twice.
    game.onAlienDestroyed(alien);
    expect(game.score, scoreBefore + points);
  });

  testWidgets('enemy projectile can be spawned and forced deterministically', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    expect(game.world.descendants().whereType<EnemyLaser>(), isEmpty);

    game.forceEnemyShot();
    await tester.runAsync(game.ready);
    await tester.pump();
    expect(game.world.descendants().whereType<EnemyLaser>(), hasLength(1));
    expect(game.enemyProjectileCount, 1);

    game.spawnEnemyProjectile(Vector2(180, 100));
    await tester.runAsync(game.ready);
    await tester.pump();
    expect(game.world.descendants().whereType<EnemyLaser>(), hasLength(2));

    // Forced auto fire respects the max-projectile cap (pump so each
    // spawn mounts before the next cap check).
    for (var i = 0; i < 10; i++) {
      game.forceEnemyShot();
      await tester.runAsync(game.ready);
      await tester.pump();
    }
    expect(
      game.world.descendants().whereType<EnemyLaser>().length,
      lessThanOrEqualTo(GameConfig.maxEnemyProjectiles),
    );
  });

  testWidgets('enemy projectile travels downward and despawns off-screen', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    game.spawnEnemyProjectile(Vector2(180, 100));
    await tester.runAsync(game.ready);
    final projectile = game.world.descendants().whereType<EnemyLaser>().first;
    final startY = projectile.position.y;
    game.update(0.2);
    expect(projectile.position.y, greaterThan(startY));

    projectile.position.y =
        GameConfig.logicalHeight + GameConfig.enemyLaserHeight + 5;
    game.update(0.1);
    await tester.runAsync(game.ready);
    expect(
      game.world.descendants().whereType<EnemyLaser>().where(
        (e) => e == projectile,
      ),
      isEmpty,
    );
  });

  testWidgets('enemy projectile collision removes exactly one life', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    expect(game.lives, 3);

    final player = game.world.firstChild<Player>()!;
    game.spawnEnemyProjectile(player.absoluteCenter.clone());
    await tester.runAsync(game.ready);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(game.ready);

    expect(game.lives, 2);
    expect(game.world.descendants().whereType<EnemyLaser>(), isEmpty);
  });

  testWidgets(
    'repeated callbacks for the same projectile do not remove extra lives',
    (tester) async {
      final game = SpaceInvadersGame();
      await pumpPlayingGame(tester, game);
      game.enemyAutoFireEnabled = false;

      final player = game.world.firstChild<Player>()!;
      game.spawnEnemyProjectile(player.absoluteCenter.clone());
      await tester.runAsync(game.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(game.ready);
      expect(game.lives, 2);

      final projectile = EnemyLaser(
        position: player.absoluteCenter.clone(),
        onHitPlayer: game.onEnemyProjectileHitPlayer,
      );
      // Simulate duplicate collision callbacks / overlapping updates for an
      // already-consumed event while invulnerable.
      game.onEnemyProjectileHitPlayer(projectile);
      game.onEnemyProjectileHitPlayer(projectile);
      game.update(0.1);
      game.update(0.1);
      await tester.runAsync(game.ready);

      // Still invulnerable from the first hit, so no further loss.
      expect(game.lives, 2);
    },
  );

  testWidgets('losing a life resets the player and allows continued play', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    final player = game.world.firstChild<Player>()!;

    player.moveToX(GameConfig.logicalWidth + 100);
    expect(player.position.x, lessThan(GameConfig.logicalWidth));

    game.spawnEnemyProjectile(player.absoluteCenter.clone());
    await tester.runAsync(game.ready);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(game.ready);

    expect(game.lives, 2);
    expect(game.currentRouteName, SpaceInvadersGame.playRoute);
    expect(player.isMounted, isTrue);
    expect(player.position.x, Player.startX);
    expect(game.isInvulnerable, isTrue);

    // Player can still move and auto-fire after the hit.
    player.moveToX(100);
    expect(player.position.x, 100);
    game.update(GameConfig.autoFireInterval);
    await tester.runAsync(game.ready);
    expect(game.world.descendants().whereType<Laser>(), isNotEmpty);
  });

  testWidgets(
    'formation breach removes exactly one life without draining each frame',
    (tester) async {
      final game = SpaceInvadersGame();
      await pumpPlayingGame(tester, game);
      game.enemyAutoFireEnabled = false;

      final formation = game.world.firstChild<AlienFormation>()!;
      // Push the lowest part of the formation onto the danger line.
      formation.position.y = GameConfig.playerDangerLineY - formation.size.y;
      expect(
        formation.position.y + formation.size.y,
        greaterThanOrEqualTo(GameConfig.playerDangerLineY),
      );

      game.update(0);
      await tester.runAsync(game.ready);
      expect(game.lives, 2);
      expect(game.breachLatched, isTrue);

      // Lingering beyond the line must not drain further lives.
      game.clearInvulnerability();
      for (var i = 0; i < 5; i++) {
        game.update(0.1);
      }
      await tester.runAsync(game.ready);
      expect(game.lives, 2);
    },
  );

  testWidgets('losing the final life transitions to the death screen', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    game.lives = 1;
    game.clearInvulnerability();
    game.loseLife();
    await settleRoute(tester, game);

    expect(game.lives, 0);
    expect(game.isGameOver, isTrue);
    expect(game.currentRouteName, SpaceInvadersGame.deathRoute);
    expect(game.descendants().whereType<DeathScreen>(), hasLength(1));
  });

  testWidgets('death screen displays the final score', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    game.score = 150;
    game.lives = 1;
    game.clearInvulnerability();
    game.loseLife();
    await settleRoute(tester, game);

    final death = game.descendants().whereType<DeathScreen>().single;
    expect(death.score, 150);
  });

  testWidgets('restart resets lives, score, player, aliens, projectiles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(
      const Size(GameConfig.logicalWidth, GameConfig.logicalHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    // Dirty the session: score, stray projectiles.
    final alien = game.world.descendants().whereType<Alien>().first;
    game.onAlienDestroyed(alien);
    alien.removeFromParent();
    game.spawnEnemyProjectile(Vector2(180, 200));
    game.spawnEnemyProjectile(Vector2(120, 200));
    await tester.runAsync(game.ready);
    await tester.pump();
    final stalePlayer = game.world.firstChild<Player>()!;
    game.lives = 1;
    game.score = 90;
    game.clearInvulnerability();
    game.loseLife();
    await settleRoute(tester, game);
    expect(game.currentRouteName, SpaceInvadersGame.deathRoute);

    // Tap RESTART.
    await tester.tapAt(
      const Offset(
        GameConfig.logicalWidth / 2,
        GameConfig.logicalHeight * 0.61,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await settleRoute(tester, game);

    expect(game.currentRouteName, SpaceInvadersGame.playRoute);
    expect(game.lives, 3);
    expect(game.score, 0);
    expect(game.isGameOver, isFalse);
    expect(game.world.descendants().whereType<Alien>(), hasLength(15));
    expect(game.world.descendants().whereType<EnemyLaser>(), isEmpty);
    expect(game.world.descendants().whereType<Laser>(), isEmpty);
    final freshPlayer = game.world.firstChild<Player>()!;
    expect(freshPlayer, isNot(stalePlayer));
    expect(freshPlayer.position.x, Player.startX);
    expect(game.descendants().whereType<DeathScreen>(), isEmpty);
  });

  testWidgets('main menu button returns to the existing menu route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(
      const Size(GameConfig.logicalWidth, GameConfig.logicalHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    game.lives = 1;
    game.clearInvulnerability();
    game.loseLife();
    await settleRoute(tester, game);
    expect(game.currentRouteName, SpaceInvadersGame.deathRoute);

    await tester.tapAt(
      const Offset(
        GameConfig.logicalWidth / 2,
        GameConfig.logicalHeight * 0.75,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await settleRoute(tester, game);

    expect(game.currentRouteName, SpaceInvadersGame.menuRoute);
    expect(game.descendants().whereType<MainMenu>(), hasLength(1));
    expect(game.descendants().whereType<DeathScreen>(), isEmpty);
  });

  testWidgets('losing a life telegraphs with a HUD hit flash', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    final hud = game.world.firstChild<Hud>()!;
    expect(hud.isHitFlashActive, isFalse);

    game.clearInvulnerability();
    game.loseLife();
    await tester.runAsync(game.ready);

    expect(game.lives, 2);
    expect(hud.isHitFlashActive, isTrue);
    expect(hud.livesLabel, contains('HIT'));

    // Flash survives HUD state syncs while active.
    game.update(0.2);
    expect(hud.isHitFlashActive, isTrue);
    expect(hud.livesLabel, contains('HIT'));

    // And expires after the telegraph duration.
    game.update(GameConfig.hitTelegraphDuration);
    await tester.runAsync(game.ready);
    expect(hud.isHitFlashActive, isFalse);
    expect(hud.livesLabel, Hud.livesDisplay(2));
  });

  testWidgets('player flashes on and off during invulnerability', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    final player = game.world.firstChild<Player>()!;
    expect(player.isInvulnerable, isFalse);
    expect(player.isVisible, isTrue);

    game.clearInvulnerability();
    game.loseLife();
    expect(player.isInvulnerable, isTrue);

    final states = <bool>{player.isVisible};
    for (var i = 0; i < 12; i++) {
      game.update(GameConfig.invulnerabilityFlashInterval / 2);
      states.add(player.isVisible);
    }
    // Blinked both on and off.
    expect(states, containsAll({true, false}));

    // Still flashing until the window expires, then steady and visible.
    expect(player.isInvulnerable, isTrue);
    game.clearInvulnerability();
    game.update(0.01);
    expect(player.isInvulnerable, isFalse);
    expect(player.isVisible, isTrue);
  });

  testWidgets('death screen halts gameplay updates underneath', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    game.score = 60;
    game.lives = 1;
    game.clearInvulnerability();
    game.loseLife();
    await settleRoute(tester, game);

    final scoreAfterDeath = game.score;
    game.update(1.0);
    game.update(1.0);
    await tester.runAsync(game.ready);

    expect(game.score, scoreAfterDeath);
    expect(game.world.descendants().whereType<Laser>(), isEmpty);
    expect(game.world.descendants().whereType<EnemyLaser>(), isEmpty);
  });

  testWidgets('level two starts with reset lives and score', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;
    game.lives = 1;
    game.score = 90;

    await completeLevelOne(tester, game);

    expect(game.lives, GameConfig.initialLives);
    expect(game.score, 0);
  });

  testWidgets('clearing level one starts the faster level two formation', (
    tester,
  ) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    await completeLevelOne(tester, game);

    final formation = game.world.firstChild<AlienFormation>()!;
    expect(formation.speedMultiplier, 1.5);
    expect(game.world.descendants().whereType<Alien>(), hasLength(15));
    expect(
      game.world.descendants().whereType<TextComponent>().map(
        (component) => component.text,
      ),
      contains('LEVEL 2'),
    );
  });

  testWidgets('level two clears transient combat state', (tester) async {
    final game = SpaceInvadersGame();
    await pumpPlayingGame(tester, game);
    game.enemyAutoFireEnabled = false;

    final formation = game.world.firstChild<AlienFormation>()!;
    formation.position.y = GameConfig.playerDangerLineY - formation.size.y;
    game.update(0);
    game.spawnEnemyProjectile(Vector2(20, 100));
    await tester.runAsync(game.ready);
    await tester.pump();

    expect(game.breachLatched, isTrue);
    expect(game.isInvulnerable, isTrue);
    expect(game.enemyProjectileCount, 1);

    await completeLevelOne(tester, game);

    expect(game.breachLatched, isFalse);
    expect(game.isInvulnerable, isFalse);
    expect(game.player.isInvulnerable, isFalse);
    expect(game.enemyProjectileCount, 0);
  });
}
