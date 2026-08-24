import 'dart:math' as math;

/// Pure movement rules. Keep these out of Flame so they stay unit-testable.
abstract final class PlayerRules {
  /// Move [current] toward [target] at a constant [acceleration].
  static double approach(
    double current,
    double target,
    double acceleration,
    double dt,
  ) {
    final step = acceleration * dt;
    if (current < target) {
      return math.min(current + step, target);
    }
    if (current > target) {
      return math.max(current - step, target);
    }
    return current;
  }

  /// Wall on the left launches you right (facing +1), and the reverse.
  /// [lastWall] is -1 (left), 1 (right), or 0 if unknown.
  static int facingAfterWallJump({
    required int facing,
    required bool touchingLeft,
    required bool touchingRight,
    required int lastWall,
  }) {
    if (touchingLeft && !touchingRight) {
      return 1;
    }
    if (touchingRight && !touchingLeft) {
      return -1;
    }
    if (lastWall != 0) {
      return -lastWall;
    }
    return -facing;
  }
}
