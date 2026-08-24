import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/collision/collision_grid.dart';

LevelMap _box() {
  return LevelMap.parseJson(
    '''
{
  "format": 1,
  "id": "box",
  "name": "Box",
  "tileSize": 32,
  "grid": [
    "####",
    "#P.#",
    "#.C#",
    "####"
  ]
}
''',
    file: 'box.json',
  );
}

void main() {
  test('wall-jump velocity into an embedded wall ejects toward the room', () {
    final grid = CollisionGrid(_box());
    const halfW = 11.0;
    const halfH = 13.0;
    const skin = 2.0;
    // 4px inside the left wall (tile 0 is x=0..32). Room starts at x=32.
    const embeddedX = 32.0 - 4.0 + halfW; // center while overlapping the wall

    final resolved = grid.separateX(
      centerX: embeddedX,
      centerY: 48,
      halfWidth: halfW,
      halfHeight: halfH,
      skin: skin,
    );

    expect(resolved, greaterThan(32 + halfW - 0.1));
    expect(resolved, lessThan(64));
    expect(
      grid.overlapsSolid(
        Rect.fromCenter(
          center: Offset(resolved, 48),
          width: halfW * 2,
          height: halfH * 2 - skin * 2,
        ),
      ),
      isFalse,
    );
  });

  test('right wall embed ejects left into the room', () {
    final grid = CollisionGrid(_box());
    const halfW = 11.0;
    // Right wall is col 3, x=96..128. Room ends at 96.
    const embeddedX = 96.0 + 4.0 - halfW;

    final resolved = grid.separateX(
      centerX: embeddedX,
      centerY: 48,
      halfWidth: halfW,
      halfHeight: 13,
      skin: 2,
    );

    expect(resolved, lessThan(96 - halfW + 0.1));
    expect(resolved, greaterThan(32));
  });
}
