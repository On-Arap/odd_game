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
/// Ice is ignored. Mud counts. Icicles and the snowman are decoration.
///
/// When no mockup tile matches exactly, pick by cardinal neighbors (N/E/S/W)
/// first, then break ties with diagonals.
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

  /// 1x1 plot in the mockup — Hamming fallback when no edge tile matches.
  static const isolated = SnowTileSrc(112, 16);

  static final Map<int, SnowTileSrc> _catalog = _buildCatalog();

  /// Null means the block is boxed in on all 8 sides; use a flat fill color.
  static SnowTileSrc? src(LevelMap level, int col, int row) {
    final mask = _maskAt(col, row, (c, r) => blocks(level, c, r));
    if (mask == 0xFF) {
      return null;
    }
    return pick(mask);
  }

  static SnowTileSrc pick(int mask) {
    if (mask == 0xFF) {
      return isolated;
    }
    final exact = _catalog[mask];
    if (exact != null) {
      return exact;
    }
    var best = isolated;
    var bestCardinal = 9;
    var bestDiagonal = 9;
    for (final entry in _catalog.entries) {
      final cardinal = _hamming(mask, entry.key, cardinals: true);
      final diagonal = _hamming(mask, entry.key, cardinals: false);
      if (cardinal < bestCardinal ||
          (cardinal == bestCardinal && diagonal < bestDiagonal)) {
        bestCardinal = cardinal;
        bestDiagonal = diagonal;
        best = entry.value;
      }
    }
    return best;
  }

  static int _hamming(int a, int b, {required bool cardinals}) {
    var score = 0;
    for (var i = 0; i < 8; i++) {
      final isCardinal = i == _n || i == _e || i == _s || i == _w;
      if (isCardinal != cardinals) {
        continue;
      }
      if (((a >> i) & 1) != ((b >> i) & 1)) {
        score++;
      }
    }
    return score;
  }

  static bool blocks(LevelMap level, int col, int row) {
    if (col < 0 || col >= level.cols || row < 0 || row >= level.rows) {
      return true;
    }
    final cell = level.tileAt(col, row);
    return cell == TileCodes.solid || cell == TileCodes.mud;
  }

  static Map<int, SnowTileSrc> _buildCatalog() {
    final catalog = <int, SnowTileSrc>{};
    for (var ty = 0; ty < _mockup.length; ty++) {
      final line = _mockup[ty];
      for (var tx = 0; tx < line.length; tx++) {
        if (line[tx] != '#') {
          continue;
        }
        final mask = _maskAt(tx, ty, _mockupSolid);
        if (mask == 0xFF) {
          continue;
        }
        catalog.putIfAbsent(mask, () => SnowTileSrc(tx * size, ty * size));
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
