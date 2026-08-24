import 'dart:ui';

import 'package:flame/components.dart';

class GroundBlock extends RectangleComponent {
  GroundBlock({
    required super.position,
    required super.size,
    required Color color,
  }) : super(paint: Paint()..color = color);
}
