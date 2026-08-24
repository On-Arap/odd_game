import 'dart:ui';

import 'package:flame/components.dart';

class GroundBlock extends PositionComponent {
  GroundBlock.sprite({
    required Vector2 position,
    required Vector2 size,
    required Sprite sprite,
    Color? background,
  }) : _sprite = sprite,
       _color = background,
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
    if (_sprite != null) {
      if (_color != null) {
        await add(RectangleComponent(size: size, paint: Paint()..color = _color));
      }
      await add(SpriteComponent(sprite: _sprite, size: size));
      return;
    }
    await add(RectangleComponent(size: size, paint: Paint()..color = _color!));
  }
}
