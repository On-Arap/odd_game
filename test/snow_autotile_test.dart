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

  test('ice neighbors are ignored for snow autotile', () {
    final level = _map(const [
      '.....',
      '.I#I.',
      '..I..',
      '.P.C.',
    ]);
    expect(SnowAutotile.src(level, 2, 1), SnowAutotile.isolated);
  });

  test('unmatched shapes do not fall back to an interior fill tile', () {
    final pillar = _map(const [
      '.....',
      '..#..',
      '..#..',
      '.P.C.',
    ]);
    final top = SnowAutotile.src(pillar, 2, 1);
    final mid = SnowAutotile.src(pillar, 2, 2);
    expect(top, isNotNull);
    expect(mid, isNotNull);
    expect(top, isNot(const SnowTileSrc(48, 32)));
    expect(mid, isNot(const SnowTileSrc(48, 32)));
  });

  test('two-wide floating ledge uses platform end caps', () {
    final level = _map(const [
      '.....',
      '.##..',
      '.P.C.',
      '.....',
    ]);
    expect(SnowAutotile.src(level, 1, 1), const SnowTileSrc(112, 48));
    expect(SnowAutotile.src(level, 2, 1), const SnowTileSrc(144, 48));
  });

  test('T-junction base prefers underside over a snow-capped ledge', () {
    final level = _map(const [
      '......',
      '.##...',
      '..#...',
      '.###..',
      '.P..C.',
      '......',
    ]);
    // Middle of the 3-wide base: pillar above, air below — not a snow cap.
    expect(SnowAutotile.src(level, 2, 3), const SnowTileSrc(32, 64));
    // Elbow at the arm/pillar: snow on top, not a ceiling tile.
    expect(SnowAutotile.src(level, 2, 1), const SnowTileSrc(64, 16));
  });
}
