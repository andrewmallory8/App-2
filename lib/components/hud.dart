import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

import '../game_config.dart';

/// In-game HUD showing remaining lives and current score.
///
/// Briefly flashes a red `HIT!` telegraph on the lives label whenever the
/// player loses a life.
class Hud extends PositionComponent {
  Hud()
    : super(
        position: Vector2(0, 0),
        size: Vector2(GameConfig.logicalWidth, 40),
      );

  static const _livesColor = Color(0xFFB7FF4A);
  static const _hitColor = Color(0xFFFF5C5C);
  static const _scoreColor = Color(0xFFEAF6FF);

  static TextPaint _labelPaint(Color color) => TextPaint(
    style: TextStyle(
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    ),
  );

  late final TextComponent _livesText = TextComponent(
    text: livesDisplay(3),
    position: Vector2(12, 8),
    textRenderer: _labelPaint(_livesColor),
  );

  late final TextComponent _scoreText = TextComponent(
    text: scoreDisplay(0),
    position: Vector2(GameConfig.logicalWidth - 12, 8),
    anchor: Anchor.topRight,
    textRenderer: _labelPaint(_scoreColor),
  );

  int lives = 3;
  int score = 0;

  double _hitFlashTimer = 0;

  /// Whether the life-loss telegraph is currently showing.
  bool get isHitFlashActive => _hitFlashTimer > 0;

  static String livesDisplay(int lives) => 'LIVES $lives';
  static String hitDisplay(int lives) => 'LIVES $lives  HIT!';
  static String scoreDisplay(int score) => 'SCORE $score';

  String get livesLabel => _livesText.text;
  String get scoreLabel => _scoreText.text;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_livesText);
    add(_scoreText);
    _refreshLabels();
  }

  /// Push fresh game state into the visible labels.
  /// Preserves an active hit telegraph instead of overwriting it.
  void updateState({required int lives, required int score}) {
    this.lives = lives;
    this.score = score;
    _refreshLabels();
  }

  /// Telegraph a lost life: red `HIT!` flash for [GameConfig.hitTelegraphDuration].
  void flashHit() {
    _hitFlashTimer = GameConfig.hitTelegraphDuration;
    _refreshLabels();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
      if (_hitFlashTimer <= 0) {
        _hitFlashTimer = 0;
        _refreshLabels();
      }
    }
  }

  void _refreshLabels() {
    if (isHitFlashActive) {
      _livesText.text = hitDisplay(lives);
      _livesText.textRenderer = _labelPaint(_hitColor);
    } else {
      _livesText.text = livesDisplay(lives);
      _livesText.textRenderer = _labelPaint(_livesColor);
    }
    _scoreText.text = scoreDisplay(score);
  }
}
