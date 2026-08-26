abstract final class GameConfig {
  static const viewWidth = 640.0;
  static const viewHeight = 360.0;

  static const playerWidth = 32.0;
  static const playerHeight = 32.0;

  static const gravity = 1850.0;
  static const maxFallSpeed = 980.0;
  static const runSpeed = 300.0;
  static const mudSpeed = 150.0;

  /// Time to reach [runSpeed] from rest. Acceleration is constant, so a
  /// running start takes less than this.
  static const runAccelTime = 0.75;
  static const runAccel = runSpeed / runAccelTime;

  /// Time to stop from [runSpeed]. Deceleration is constant, so a slower
  /// speed takes less than this.
  static const runDecelTime = 0.3;
  static const runDecel = runSpeed / runDecelTime;
  static const jumpSpeed = -540.0;
  static const wallJumpSpeed = -500.0;
  static const wallJumpX = 240.0;

  /// Extra gravity while rising after jump is released. 1 = full arc.
  /// Higher = shorter tap jump. Full hop (button held) is unchanged.
  static const jumpReleaseGravity = 5.0;

  /// Full air speed for this long, then horizontal speed drops toward [airMinSpeedFactor].
  static const airFullSpeedTime = 0.2;
  static const airDecayTime = 1.5;
  static const airMinSpeedFactor = 0.25;

  /// Facteur de vitesse aérienne : 1 un moment, puis chute vers [airMinSpeedFactor].
  static double airSpeedFactor(double airTime) {
    if (airTime <= airFullSpeedTime) {
      return 1;
    }
    final t = ((airTime - airFullSpeedTime) / airDecayTime).clamp(0.0, 1.0);
    return 1 - t * (1 - airMinSpeedFactor);
  }

  static const coyoteTime = 0.09;
  static const jumpBuffer = 0.12;
  static const wallCoyoteTime = 0.10;

  static const wallProbe = 3.0;
  static const skin = 2.0;

  static const deathMargin = 64.0;
  static const maxDt = 1 / 50;
}
