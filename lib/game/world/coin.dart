import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:odd/game/palette.dart';

class Coin extends PositionComponent {
  Coin({required Vector2 center, required double tileSize})
    : _origin = center.clone(),
      super(
        position: center,
        size: Vector2.all(tileSize * 0.45),
        anchor: Anchor.center,
        priority: 10,
      );

  final Vector2 _origin;
  final Paint _fill = Paint()..color = Palette.coin;
  final Paint _inner = Paint()..color = Palette.coinInner;
  double _time = 0;
  bool collected = false;

  Rect get hitbox {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x * 0.85,
      height: size.y * 0.85,
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

  @override
  void render(Canvas canvas) {
    final outer = size.toRect();
    canvas.drawOval(outer, _fill);
    canvas.drawOval(outer.deflate(size.x * 0.22), _inner);
  }
}
