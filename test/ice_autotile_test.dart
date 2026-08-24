import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/world/ice_autotile.dart';

LevelMap _map(List<String> grid) {
  return LevelMap.parseJson(
    '''
{
  "format": 1,
  "id": "ice",
  "name": "Ice",
  "tileSize": 16,
  "grid": [${grid.map((row) => '"$row"').join(',')}]
}
''',
    file: 'ice.json',
  );
}

void main() {
  test('single ice tile uses the left cap', () {
    final level = _map(const [
      '.....',
      '..I..',
      '.P.C.',
      '.....',
    ]);
    expect(IceAutotile.src(level, 2, 1), IceAutotile.left);
  });

  test('ice run uses left, middle, and right caps', () {
    final level = _map(const [
      '......',
      '.IIII.',
      '.P..C.',
      '......',
    ]);
    expect(IceAutotile.src(level, 1, 1), IceAutotile.left);
    expect(IceAutotile.src(level, 4, 1), IceAutotile.right);

    final midA = IceAutotile.src(level, 2, 1);
    final midB = IceAutotile.src(level, 3, 1);
    expect(midA == IceAutotile.middleA || midA == IceAutotile.middleB, isTrue);
    expect(midB == IceAutotile.middleA || midB == IceAutotile.middleB, isTrue);
  });

  test('middle pick is stable for the same cell', () {
    final level = _map(const [
      '......',
      '.IIII.',
      '.P..C.',
      '......',
    ]);
    expect(IceAutotile.src(level, 2, 1), IceAutotile.src(level, 2, 1));
  });

  test('two-tile run is only left and right', () {
    final level = _map(const [
      '.....',
      '.II..',
      '.P.C.',
      '.....',
    ]);
    expect(IceAutotile.src(level, 1, 1), IceAutotile.left);
    expect(IceAutotile.src(level, 2, 1), IceAutotile.right);
  });

  test('snow next to ice does not extend the ice run', () {
    final level = _map(const [
      '......',
      '.#II#.',
      '.P..C.',
      '......',
    ]);
    expect(IceAutotile.src(level, 2, 1), IceAutotile.left);
    expect(IceAutotile.src(level, 3, 1), IceAutotile.right);
  });
}
