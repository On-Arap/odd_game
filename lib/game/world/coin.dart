import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:odd/game/sprites.dart';

/// Pièce animée qui flotte un peu, puis disparaît à la collecte.
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

  /// Hitbox un peu plus petite que le sprite.
  Rect get hitbox {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x * 0.85,
      height: size.y * 0.85,
    );
  }

  /// 8 frames de `coin_gold.png`.
  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache(GameSprites.coin),
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.08,
        textureSize: Vector2.all(16),
      ),
    );
  }

  /// Marque la pièce et la retire du monde.
  void collect() {
    collected = true;
    removeFromParent();
  }

  /// Oscillation verticale autour du point d'origine.
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y = _origin.y + math.sin(_time * 4) * 3;
  }
}
