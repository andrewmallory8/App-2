import 'dart:math';
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

/// Where an alien currently flies.
enum AlienFlightState {
  /// Marching with the formation (child of [AlienFormation]).
  inFormation,

  /// Broken away: zig-zagging down through world space (child of [World]).
  diving,

  /// Wrapped past the bottom and steering back to its formation slot.
  returning,
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

  /// Set the first time this alien is destroyed so score/collisions
  /// stay idempotent when multiple lasers overlap the same alien.
  bool destroyed = false;

  /// Dive-attack flight state. The game moves the alien between the
  /// formation and the world when a dive starts; [update] then drives
  /// the dive/return motion itself.
  AlienFlightState flightState = AlienFlightState.inFormation;

  /// Local slot inside [homeParent] this diver docks back into.
  Vector2? homePosition;

  /// Formation this diver belongs to. Typed as [PositionComponent] to
  /// avoid a circular import with the formation component.
  PositionComponent? homeParent;

  /// Time since the dive started; drives the zig-zag sine wave.
  double diveTime = 0;

  /// World x the zig-zag oscillates around (captured at dive start).
  double diveBaseX = 0;

  /// Random sine offset so simultaneous divers don't move in lockstep.
  double zigZagPhase = 0;

  /// Scales dive/return speeds (formation passes its speed multiplier).
  double diveSpeedMultiplier = 1;

  /// Countdown to the next projectile while diving; ticked by the game,
  /// which owns spawning so the shared projectile cap still applies.
  double diveFireCooldown = GameConfig.diveFireInterval;

  bool get isDiving => flightState == AlienFlightState.diving;
  bool get isReturning => flightState == AlienFlightState.returning;

  /// Arm the dive after the game reparents this alien into the world.
  /// [worldTopLeft] is the alien's world-space top-left at detach time,
  /// [homeSlot] its local slot to dock back into.
  void beginDive({
    required Vector2 worldTopLeft,
    required PositionComponent homeParent,
    required Vector2 homeSlot,
    double speedMultiplier = 1,
    double phase = 0,
  }) {
    position.setFrom(worldTopLeft);
    this.homeParent = homeParent;
    homePosition = homeSlot.clone();
    diveSpeedMultiplier = speedMultiplier;
    zigZagPhase = phase;
    diveTime = 0;
    diveBaseX = worldTopLeft.x;
    diveFireCooldown = GameConfig.diveFireInterval;
    flightState = AlienFlightState.diving;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (destroyed) {
      return;
    }
    switch (flightState) {
      case AlienFlightState.inFormation:
        break;
      case AlienFlightState.diving:
        _updateDiving(dt);
        break;
      case AlienFlightState.returning:
        _updateReturning(dt);
        break;
    }
  }

  void _updateDiving(double dt) {
    diveTime += dt;
    position.y += GameConfig.diveFallSpeed * diveSpeedMultiplier * dt;
    final targetX =
        diveBaseX +
        sin(diveTime * GameConfig.diveZigZagFrequency + zigZagPhase) *
            GameConfig.diveZigZagAmplitude;
    position.x = targetX.clamp(
      GameConfig.alienHorizontalMargin / 2,
      GameConfig.logicalWidth -
          size.x -
          GameConfig.alienHorizontalMargin / 2,
    );
    if (position.y > GameConfig.logicalHeight + size.y) {
      // Off the bottom: wrap above the top and steer home.
      position.y = -size.y - 4;
      flightState = AlienFlightState.returning;
    }
  }

  void _updateReturning(double dt) {
    final home = homeParent;
    final slot = homePosition;
    if (home == null || slot == null || !home.isMounted) {
      // Formation is gone (e.g. level transition); despawn quietly.
      removeFromParent();
      return;
    }
    final target = home.position + slot;
    final toTarget = target - position;
    final distance = toTarget.length;
    if (distance <= GameConfig.diveReturnSnapDistance) {
      removeFromParent();
      position.setFrom(slot);
      homeParent = null;
      homePosition = null;
      flightState = AlienFlightState.inFormation;
      home.add(this);
      return;
    }
    final step = GameConfig.diveReturnSpeed * diveSpeedMultiplier * dt;
    if (distance <= step) {
      position.setFrom(target);
    } else {
      position.add(toTarget.normalized() * step);
    }
  }
}
