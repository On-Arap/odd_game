abstract final class GameConfig {
  static const viewWidth = 640.0;
  static const viewHeight = 360.0;

  static const playerWidth = 32.0;
  static const playerHeight = 32.0;

  static const gravity = 1350.0;
  static const maxFallSpeed = 980.0;
  static const runSpeed = 400.0;
  static const mudSpeed = 150.0;
  static const airMaxSpeed = 300.0;

  /// Time to reach [runSpeed] from rest. Acceleration is constant, so a
  /// running start takes less than this.
  static const runAccelTime = 0.3;
  static const runAccel = runSpeed / runAccelTime;

  /// Time to stop from [runSpeed]. Deceleration is constant, so a slower
  /// speed takes less than this.
  static const runDecelTime = 0.5;
  static const runDecel = runSpeed / runDecelTime;

  /// Time to reach [airMaxSpeed] from rest while airborne with run held.
  /// Lower = more aerial drift control.
  static const airAccelTime = 0.45;
  static const airAccel = airMaxSpeed / airAccelTime;

  /// Time to stop from [airMaxSpeed] in air when run is released.
  /// Higher = more glide / easier to feather.
  static const airDecelTime = 0.2;
  static const airDecel = airMaxSpeed / airDecelTime;
  static const jumpSpeed = -540.0;
  static const wallJumpSpeed = -500.0;
  static const wallJumpX = 240.0;

  /// Extra gravity while rising after jump is released. 1 = full arc.
  /// Higher = shorter tap jump. Full hop (button held) is unchanged.
  static const jumpReleaseGravity = 5.0;

  /// Grace window after leaving the ground. You can still do a normal jump
  /// for this long even if you already walked off a ledge.
  /// Higher = more "I pressed jump a bit late" forgiveness.
  static const coyoteTime = 0.09;

  /// Opposite of coyote: jump pressed slightly before landing still fires
  /// when you touch the ground.
  static const jumpBuffer = 0.12;

  /// Same idea as [coyoteTime], for walls. After you leave a wall, you can
  /// still wall-jump for this long.
  /// Higher = easier wall-jumps when you kick off a bit late.
  static const wallCoyoteTime = 0.10;

  /// How far beside the player we look for a wall (pixels). The wall-jump
  /// check is a thin rectangle this wide to the left/right.
  /// Higher = wall-jump from farther away (more sticky).
  static const wallProbe = 3.0;

  /// Shrink on the hitbox used for collisions, so corners don't snag.
  /// Horizontal resolve ignores this many px at top/bottom; vertical
  /// resolve ignores this many px on left/right. The feet probe also insets.
  /// Higher = less corner snag, a bit more tile overlap.
  static const skin = 2.0;

  static const deathMargin = 64.0;
  static const maxDt = 1 / 50;
}
