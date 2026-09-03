import 'dart:math';
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import 'components/alien.dart';
import 'components/alien_formation.dart';
import 'components/enemy_laser.dart';
import 'components/extra_ship.dart';
import 'components/hud.dart';
import 'components/laser.dart';
import 'components/player.dart';
import 'death_screen.dart';
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
  static const String deathRoute = '/death';
  static const Color sceneBackgroundColor = Color(0xFF10131A);

  late final RouterComponent router;
  late Player player;
  int _level = 1;
  int _aliensDefeated = 0;
  TextComponent? _levelLabel;
  AlienFormation? _alienFormation;
  Map<AlienVariant, Sprite>? _alienSprites;

  static int get _aliensNeededForLevelTwo =>
      GameConfig.alienColumns * AlienVariant.values.length;

  // --- Testable game state ---
  int lives = GameConfig.initialLives;
  int score = 0;
  bool isGameOver = false;

  double _invulnerabilityTimer = 0;
  bool _breachLatched = false;
  double _enemyFireTimer = 0;
  double _diveTimer = 0;
  final Set<Alien> _scoredAliens = {};

  /// Injectable randomness for enemy fire; tests may seed or replace it.
  Random random = Random();

  /// When false, automatic timed enemy fire is skipped.
  /// Tests use [forceEnemyShot]/[spawnEnemyProjectile] instead.
  bool enemyAutoFireEnabled = true;

  /// When false, automatic timed dive attacks are skipped.
  /// Tests use [forceDiveAttack] instead.
  bool diveAttackEnabled = true;

  String get currentRouteName => router.currentRoute.name!;

  bool get _isPlaying => router.isMounted && currentRouteName == playRoute;

  bool get isInvulnerable => _invulnerabilityTimer > 0;
  bool get breachLatched => _breachLatched;

  int get enemyProjectileCount {
    if (!_isPlaying) {
      return 0;
    }
    return world.descendants().whereType<EnemyLaser>().length;
  }

  /// Aliens currently diving or returning (detached from the formation).
  int get activeDiverCount {
    if (!_isPlaying) {
      return 0;
    }
    return world
        .descendants()
        .whereType<Alien>()
        .where(
          (alien) =>
              !alien.destroyed &&
              !alien.isRemoved &&
              alien.flightState != AlienFlightState.inFormation,
        )
        .length;
  }

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
        deathRoute: Route(
          () => DeathScreen(
            score: score,
            onRestart: startGame,
            onMainMenu: goToMenu,
          ),
          maintainState: false,
        ),
      },
    );
    add(router);
  }

  void startGame() {
    _level = 1;
    _aliensDefeated = 0;
    _resetSession();
    router.pushReplacementNamed(playRoute);
  }

  void goToMenu() {
    router.pushReplacementNamed(menuRoute);
  }

  void _resetSession() {
    lives = GameConfig.initialLives;
    score = 0;
    isGameOver = false;
    _invulnerabilityTimer = 0;
    _breachLatched = false;
    _enemyFireTimer = 0;
    _diveTimer = 0;
    _scoredAliens.clear();
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
    final hud = Hud()..updateState(lives: lives, score: score);
    return World(
      children: [
        levelLabel,
        formation,
        ExtraShip(sprite: Sprite(images.fromCache('extra.png'))),
        player,
        hud,
      ],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isPlaying || isGameOver) {
      return;
    }
    if (_invulnerabilityTimer > 0) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer < 0) {
        _invulnerabilityTimer = 0;
      }
    }
    _syncPlayerFlash();
    if (enemyAutoFireEnabled) {
      _enemyFireTimer += dt;
      final fireInterval = _currentEnemyFireInterval;
      if (_enemyFireTimer >= fireInterval) {
        _enemyFireTimer -= fireInterval;
        _maybeFireEnemyShot();
      }
    }
    if (diveAttackEnabled) {
      _updateDiveAttacks(dt);
    }
    checkFormationBreach();
    _updateHud();
  }

  void _updateHud() {
    if (!_isPlaying) {
      return;
    }
    final hud = world.firstChild<Hud>();
    hud?.updateState(lives: lives, score: score);
  }

  /// Mirror the invulnerability window onto the player's blink state.
  /// Transition-aware on the player side, so per-frame sync is cheap.
  void _syncPlayerFlash() {
    if (!_isPlaying) {
      return;
    }
    try {
      player.setInvulnerable(_invulnerabilityTimer > 0);
    } catch (_) {
      // Player not yet mounted; the next frame will sync.
    }
  }

  /// Telegraph the lost life on the HUD hit flash.
  void _flashHudHit() {
    if (!_isPlaying) {
      return;
    }
    world.firstChild<Hud>()?.flashHit();
  }

  // --- Scoring ---

  /// Award points for a destroyed alien exactly once per instance.
  void onAlienDestroyed(Alien alien) {
    if (isGameOver) {
      return;
    }
    if (!_scoredAliens.add(alien)) {
      return;
    }
    score += alien.variant.points;
    _onAlienDestroyed();
    _updateHud();
  }

  // --- Enemy fire ---

  /// Fire faster as fewer aliens remain, making the end of a wave tense.
  double get _currentEnemyFireInterval {
    final formation = world.firstChild<AlienFormation>();
    if (formation == null || formation.totalAlienCount == 0) {
      return GameConfig.enemyFireInterval;
    }
    final defeatedRatio =
        1 - formation.livingAlienCount / formation.totalAlienCount;
    return GameConfig.enemyFireInterval -
        (GameConfig.enemyFireInterval - GameConfig.enemyMinimumFireInterval) *
            defeatedRatio;
  }

  void _maybeFireEnemyShot() {
    if (!_isPlaying || isGameOver) {
      return;
    }
    final attackers = _frontlineAttackers();
    if (attackers.isEmpty) {
      return;
    }
    if (world.descendants().whereType<EnemyLaser>().length >=
        GameConfig.maxEnemyProjectiles) {
      return;
    }
    attackers.sort(
      (left, right) => (left.absoluteCenter.x - player.position.x)
          .abs()
          .compareTo((right.absoluteCenter.x - player.position.x).abs()),
    );
    // Pick one of the three closest exposed aliens. This feels aimed without
    // making every shot perfectly accurate or unfair.
    final preferredCount = min(3, attackers.length);
    final shooter = attackers[random.nextInt(preferredCount)];
    spawnEnemyProjectile(shooter.absoluteCenter.clone());
  }

  /// Returns only the lowest surviving alien in each column. Enemies behind
  /// another invader cannot shoot through their own formation.
  List<Alien> _frontlineAttackers() {
    final formation = world.firstChild<AlienFormation>();
    if (formation == null) {
      return [];
    }
    final byColumn = <int, Alien>{};
    final columnWidth = GameConfig.alienWidth + GameConfig.alienColumnGap;
    for (final alien in formation.children.whereType<Alien>()) {
      if (alien.destroyed || alien.isRemoved) {
        continue;
      }
      if (alien.flightState != AlienFlightState.inFormation) {
        continue;
      }
      final column = (alien.position.x / columnWidth).round();
      final current = byColumn[column];
      if (current == null || alien.position.y > current.position.y) {
        byColumn[column] = alien;
      }
    }
    return byColumn.values.toList();
  }

  /// Deterministic helper: fire from the first alien, bypassing timers.
  void forceEnemyShot() {
    if (!_isPlaying || isGameOver) {
      return;
    }
    final attackers = _frontlineAttackers();
    if (attackers.isEmpty) {
      return;
    }
    if (world.descendants().whereType<EnemyLaser>().length >=
        GameConfig.maxEnemyProjectiles) {
      return;
    }
    spawnEnemyProjectile(attackers.first.absoluteCenter.clone());
  }

  /// Deterministic helper: spawn an enemy projectile at an exact position.
  void spawnEnemyProjectile(Vector2 position) {
    if (!_isPlaying || isGameOver) {
      return;
    }
    world.add(
      EnemyLaser(
        position: position.clone(),
        onHitPlayer: onEnemyProjectileHitPlayer,
      ),
    );
  }

  // --- Dive attacks ---

  /// Tick the dive scheduler and diver fire cooldowns. Divers fire while
  /// flying downwards; the shared projectile cap still applies.
  void _updateDiveAttacks(double dt) {
    _diveTimer += dt;
    if (_diveTimer >= GameConfig.diveAttackInterval) {
      _diveTimer -= GameConfig.diveAttackInterval;
      tryLaunchDive();
    }
    if (isGameOver) {
      return;
    }
    final divers = world
        .descendants()
        .whereType<Alien>()
        .where((alien) => alien.isDiving && !alien.destroyed && !alien.isRemoved)
        .toList();
    for (final diver in divers) {
      diver.diveFireCooldown -= dt;
      if (diver.diveFireCooldown > 0) {
        continue;
      }
      diver.diveFireCooldown += GameConfig.diveFireInterval;
      if (world.descendants().whereType<EnemyLaser>().length >=
          GameConfig.maxEnemyProjectiles) {
        continue;
      }
      world.add(
        EnemyLaser(
          position: Vector2(
            diver.position.x + diver.size.x / 2,
            diver.position.y + diver.size.y / 2,
          ),
          onHitPlayer: onEnemyProjectileHitPlayer,
        ),
      );
    }
  }

  /// Detach one random formation alien into a dive, if any are eligible
  /// and the simultaneous-diver cap is not reached. Returns true when
  /// a dive started.
  bool tryLaunchDive() {
    if (!_isPlaying || isGameOver) {
      return false;
    }
    final formation = world.firstChild<AlienFormation>();
    if (formation == null) {
      return false;
    }
    if (activeDiverCount >= GameConfig.maxSimultaneousDivers) {
      return false;
    }
    final candidates = formation.children
        .whereType<Alien>()
        .where(
          (alien) =>
              !alien.destroyed &&
              !alien.isRemoved &&
              alien.flightState == AlienFlightState.inFormation,
        )
        .toList();
    if (candidates.isEmpty) {
      return false;
    }
    final alien = candidates[random.nextInt(candidates.length)];
    final homeSlot = alien.position.clone();
    // The formation sits directly in the world, so the alien's world
    // top-left is the formation offset plus its local slot.
    final worldTopLeft = formation.position + homeSlot;
    alien.removeFromParent();
    world.add(alien);
    alien.beginDive(
      worldTopLeft: worldTopLeft,
      homeParent: formation,
      homeSlot: homeSlot,
      speedMultiplier: formation.speedMultiplier,
      phase: random.nextDouble() * 2 * pi,
    );
    return true;
  }

  /// Deterministic helper: launch one dive immediately, bypassing timers.
  bool forceDiveAttack() => tryLaunchDive();

  /// Single entry point for enemy-projectile hits; idempotent per projectile
  /// via [EnemyLaser.hasHit] plus the invulnerability window.
  void onEnemyProjectileHitPlayer(EnemyLaser projectile) {
    if (isGameOver || !_isPlaying) {
      return;
    }
    if (isInvulnerable) {
      return;
    }
    loseLife(projectile: projectile);
  }

  // --- Lives / breach / death ---

  /// Lose exactly one life. Removes [projectile] when the loss came from
  /// an enemy shot, resets the player when lives remain, or ends the game.
  void loseLife({EnemyLaser? projectile}) {
    if (isGameOver) {
      return;
    }
    projectile?.removeFromParent();
    lives -= 1;
    if (lives <= 0) {
      lives = 0;
      _updateHud();
      _handleGameOver();
      return;
    }
    if (_isPlaying) {
      try {
        player.resetToStart();
        player.setInvulnerable(true);
      } catch (_) {
        // Player not yet mounted (e.g. very early reset); ignore.
      }
    }
    _invulnerabilityTimer = GameConfig.invulnerabilityDuration;
    _flashHudHit();
    _updateHud();
  }

  /// Detect when the lowest part of the formation reaches the danger line.
  /// Latched so a formation lingering beyond the line costs only one life.
  void checkFormationBreach() {
    if (isGameOver || !_isPlaying || _breachLatched) {
      return;
    }
    final formation = world.firstChild<AlienFormation>();
    if (formation == null) {
      return;
    }
    final bottom = formation.position.y + formation.size.y;
    if (bottom >= GameConfig.playerDangerLineY) {
      _breachLatched = true;
      loseLife();
    }
  }

  void _handleGameOver() {
    if (isGameOver) {
      return;
    }
    isGameOver = true;
    router.pushReplacementNamed(deathRoute);
  }

  /// Test helper: expire the post-hit invulnerability window.
  void clearInvulnerability() {
    _invulnerabilityTimer = 0;
    try {
      player.setInvulnerable(false);
    } catch (_) {
      // Player not yet mounted; nothing to unsync.
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_isPlaying || isGameOver) {
      return;
    }
    event.handled = true;
    _movePlayerToCanvasX(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isPlaying || isGameOver) {
      return;
    }
    event.handled = true;
    _movePlayerToCanvasX(event.canvasEndPosition);
  }

  void _movePlayerToCanvasX(Vector2 canvasPosition) {
    player.moveToX(camera.globalToLocal(canvasPosition).x);
  }

  void _fireLaser(Vector2 origin) {
    if (!_isPlaying || isGameOver) {
      return;
    }
    world.add(Laser(position: origin, onAlienDestroyed: onAlienDestroyed));
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
    lives = GameConfig.initialLives;
    score = 0;
    _breachLatched = false;
    _enemyFireTimer = 0;
    _diveTimer = 0;
    clearInvulnerability();
    for (final projectile
        in world.descendants().whereType<EnemyLaser>().toList()) {
      projectile.removeFromParent();
    }
    // Despawn stray divers whose formation is going away; the fresh
    // formation spawns its own roster.
    for (final diver in world
        .descendants()
        .whereType<Alien>()
        .where(
          (alien) => alien.flightState != AlienFlightState.inFormation,
        )
        .toList()) {
      diver.removeFromParent();
    }
    _levelLabel?.text = 'LEVEL 2';
    _alienFormation?.removeFromParent();
    final sprites = _alienSprites;
    if (sprites != null) {
      final formation = AlienFormation(sprites: sprites, speedMultiplier: 1.5);
      _alienFormation = formation;
      world.add(formation);
    }
  }
}
