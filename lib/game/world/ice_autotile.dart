import 'package:odd/domain/level_map.dart';
import 'package:odd/game/world/snow_autotile.dart';

/// Horizontal ice runs in `tileset_snow.png`: left / middle / right caps.
///
/// A consecutive row of `I` tiles uses:
/// - first: (112, 80)
/// - last: (160, 80)
/// - middle: (128, 80) or (144, 80), chosen stably per cell
abstract final class IceAutotile {
  static const size = SnowAutotile.size;

  static const left = SnowTileSrc(112, 80);
  static const middleA = SnowTileSrc(128, 80);
  static const middleB = SnowTileSrc(144, 80);
  static const right = SnowTileSrc(160, 80);

  static SnowTileSrc src(LevelMap level, int col, int row) {
    final iceLeft = _isIce(level, col - 1, row);
    final iceRight = _isIce(level, col + 1, row);
    if (!iceLeft) {
      return left;
    }
    if (!iceRight) {
      return right;
    }
    return _middle(col, row);
  }

  static SnowTileSrc _middle(int col, int row) {
    // Stable across restarts so the level does not flicker.
    final pick = Object.hash(col, row) & 1;
    return pick == 0 ? middleA : middleB;
  }

  static bool _isIce(LevelMap level, int col, int row) {
    if (col < 0 || col >= level.cols || row < 0 || row >= level.rows) {
      return false;
    }
    return level.tileAt(col, row) == TileCodes.ice;
  }
}
