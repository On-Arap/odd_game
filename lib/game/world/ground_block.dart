import 'dart:ui';

import 'package:flame/components.dart';

class GroundBlock extends PositionComponent {
  GroundBlock.sprite({
    required Vector2 position,
    required Vector2 size,
    required Sprite sprite,
  }) : _sprite = sprite,
       _color = null,
       super(position: position, size: size);

  GroundBlock.color({
    required Vector2 position,
    required Vector2 size,
    required Color color,
  }) : _sprite = null,
       _color = color,
       super(position: position, size: size);

  final Sprite? _sprite;
  final Color? _color;

  @override
  Future<void> onLoad() async {
    final child = _sprite != null
        ? SpriteComponent(sprite: _sprite!, size: size)
        : RectangleComponent(size: size, paint: Paint()..color = _color!);
    await add(child);
  }
}
