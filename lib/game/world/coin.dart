import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class Coin extends SpriteAnimationComponent with HasGameReference {
  Coin({required Vector2 center})
    : _origin = center.clone(),
      super(
        position: center,
        size: Vector2.all(16),
        anchor: Anchor.center,
        priority: 10,
      );

  final Vector2 _origin;
  double _time = 0;
  bool collected = false;

  Rect get hitbox {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x * 0.85,
      height: size.y * 0.85,
    );
  }

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('objects/coin_gold.png'),
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.08,
        textureSize: Vector2.all(16),
      ),
    );
  }

  void collect() {
    collected = true;
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y = _origin.y + math.sin(_time * 4) * 3;
  }
}
