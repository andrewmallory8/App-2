abstract final class GameConfig {
  static const double logicalWidth = 360;
  static const double logicalHeight = 720;

  static const double spriteScale = 1;
  static const double playerSourceWidth = 60;
  static const double playerSourceHeight = 30;
  static const double playerWidth = playerSourceWidth * spriteScale;
  static const double playerHeight = playerSourceHeight * spriteScale;
  static const double playerHorizontalMargin = 12;
  static const double playerBottomMargin = 52;
  static const double autoFireInterval = 0.72;

  static const double laserWidth = 4;
  static const double laserHeight = 14;
  static const double laserSpeed = 360;

  static const double extraShipSourceWidth = 40;
  static const double extraShipSourceHeight = 20;
  static const double extraShipWidth = extraShipSourceWidth * spriteScale;
  static const double extraShipHeight = extraShipSourceHeight * spriteScale;
  static const double extraShipInitialX = 64;
  static const double extraShipY = 64;
  static const double extraShipSpeed = 72;
  static const double extraShipPause = 4.5;

  static const double alienSourceWidth = 40;
  static const double alienSourceHeight = 32;
  static const double alienWidth = alienSourceWidth * spriteScale;
  static const double alienHeight = alienSourceHeight * spriteScale;

  static const int alienColumns = 5;
  static const double alienColumnGap = 12;
  static const double alienRowGap = 12;
  static const double alienFormationTop = 132;
  static const double alienFormationWidth =
      alienColumns * alienWidth + (alienColumns - 1) * alienColumnGap;
  static const double alienFormationHeight = 3 * alienHeight + 2 * alienRowGap;
  static const double alienHorizontalMargin = 24;
  static const double alienMarchSpeed = 44;
  static const double alienStepDown = 14;
}
