import 'package:odd/domain/level_map.dart';

/// Pixel origin of a 16x16 tile inside `tileset_snow.png`.
class SnowTileSrc {
  const SnowTileSrc(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is SnowTileSrc && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Picks a snow tile by matching the 8 cells around a block to the mockup
/// in `tileset_snow.png`.
///
/// Off-map cells count as solid. Empty, coins, and the player do not.
/// Icicles and the snowman in the PNG are decoration, not terrain cases.
abstract final class SnowAutotile {
  static const size = 16.0;

  static const _n = 0;
  static const _e = 2;
  static const _s = 4;
  static const _w = 6;

  static const _dx = [0, 1, 1, 1, 0, -1, -1, -1];
  static const _dy = [-1, -1, 0, 1, 1, 1, 0, -1];

  /// Terrain occupancy of the mockup, one character per 16px cell (`#` = tile).
  static const _mockup = [
    '...........',
    '..###..#...',
    '.#####.....',
    '.#####.###.',
    '.#####.....',
    '...........',
  ];

  static final Map<int, SnowTileSrc> _catalog = _buildCatalog();
  static final SnowTileSrc _fallback = _catalog[0xFF]!;

  /// Null means the block is boxed in on all 8 sides; use a flat fill color.
  static SnowTileSrc? src(LevelMap level, int col, int row) {
    final mask = _maskAt(col, row, (c, r) => blocks(level, c, r));
    if (mask == 0xFF) {
      return null;
    }
    return pick(mask);
  }

  static SnowTileSrc pick(int mask) {
    final exact = _catalog[mask];
    if (exact != null) {
      return exact;
    }
    var best = _fallback;
    var bestScore = 1 << 30;
    for (final entry in _catalog.entries) {
      var score = 0;
      for (var i = 0; i < 8; i++) {
        if (((mask >> i) & 1) != ((entry.key >> i) & 1)) {
          score += i == _n || i == _e || i == _s || i == _w ? 2 : 1;
        }
      }
      if (score < bestScore) {
        bestScore = score;
        best = entry.value;
      }
    }
    return best;
  }

  static bool blocks(LevelMap level, int col, int row) {
    if (col < 0 || col >= level.cols || row < 0 || row >= level.rows) {
      return true;
    }
    return TileCodes.isSolid(level.tileAt(col, row));
  }

  static Map<int, SnowTileSrc> _buildCatalog() {
    final catalog = <int, SnowTileSrc>{};
    for (var ty = 0; ty < _mockup.length; ty++) {
      final line = _mockup[ty];
      for (var tx = 0; tx < line.length; tx++) {
        if (line[tx] != '#') {
          continue;
        }
        catalog.putIfAbsent(
          _maskAt(tx, ty, _mockupSolid),
          () => SnowTileSrc(tx * size, ty * size),
        );
      }
    }
    return catalog;
  }

  static bool _mockupSolid(int col, int row) {
    if (row < 0 || row >= _mockup.length) {
      return false;
    }
    final line = _mockup[row];
    if (col < 0 || col >= line.length) {
      return false;
    }
    return line[col] == '#';
  }

  static int _maskAt(int col, int row, bool Function(int col, int row) solid) {
    var mask = 0;
    for (var i = 0; i < 8; i++) {
      if (solid(col + _dx[i], row + _dy[i])) {
        mask |= 1 << i;
      }
    }
    return mask;
  }
}
