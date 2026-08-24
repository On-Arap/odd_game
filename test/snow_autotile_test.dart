import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/world/snow_autotile.dart';

LevelMap _map(List<String> grid) {
  return LevelMap.parseJson(
    '''
{
  "format": 1,
  "id": "auto",
  "name": "Auto",
  "tileSize": 16,
  "grid": [${grid.map((row) => '"$row"').join(',')}]
}
''',
    file: 'auto.json',
  );
}

void main() {
  test('snow-capped floor matches the mockup top-middle tile', () {
    final level = _map(const [
      '#####',
      '#P.C#',
      '#####',
      '#####',
    ]);
    expect(SnowAutotile.src(level, 2, 2), const SnowTileSrc(48, 16));
  });

  test('isolated block, and coins/player do not count as neighbors', () {
    final level = _map(const [
      '.....',
      '..#..',
      '.P.C.',
      '.....',
    ]);
    expect(SnowAutotile.src(level, 2, 1), const SnowTileSrc(112, 16));
  });

  test('off-map cells count as solid', () {
    final level = _map(const [
      '##...',
      '##.P.',
      '##.C.',
    ]);
    expect(SnowAutotile.src(level, 0, 1), isNull);
    expect(SnowAutotile.src(level, 1, 1), const SnowTileSrc(80, 48));
  });

  test('floating platform matches the 3-wide ledge in the mockup', () {
    final level = _map(const [
      '.....',
      '.###.',
      '.P.C.',
      '.....',
    ]);
    expect(SnowAutotile.src(level, 1, 1), const SnowTileSrc(112, 48));
    expect(SnowAutotile.src(level, 2, 1), const SnowTileSrc(128, 48));
    expect(SnowAutotile.src(level, 3, 1), const SnowTileSrc(144, 48));
  });

  test('wide ceiling underside matches the mockup bottom tiles', () {
    final level = _map(const [
      '#####',
      '#####',
      '#P.C#',
      '#####',
    ]);
    expect(SnowAutotile.src(level, 2, 1), const SnowTileSrc(32, 64));
  });
}
