import 'dart:ui';

import 'package:odd/domain/level_map.dart';

class CollisionGrid {
  CollisionGrid(this.level);

  final LevelMap level;

  double get tileSize => level.tileSize;

  bool overlapsSolid(Rect hitbox) {
    return _solidTiles(hitbox).isNotEmpty;
  }

  /// Push [centerX] out of solids. Uses the tile's nearer face, not velocity,
  /// so a wall jump while slightly embedded cannot eject you through the wall.
  double separateX({
    required double centerX,
    required double centerY,
    required double halfWidth,
    required double halfHeight,
    required double skin,
  }) {
    var x = centerX;
    for (var i = 0; i < 8; i++) {
      final probe = Rect.fromLTRB(
        x - halfWidth,
        centerY - halfHeight + skin,
        x + halfWidth,
        centerY + halfHeight - skin,
      );
      final tiles = _solidTiles(probe);
      if (tiles.isEmpty) {
        return x;
      }
      final tile = _deepestTile(
        tiles,
        penetration: (rect) {
          final left = (x + halfWidth) - rect.left;
          final right = rect.right - (x - halfWidth);
          return left < right ? left : right;
        },
      );
      const epsilon = 0.05;
      if (x < tile.center.dx) {
        x = tile.left - halfWidth - epsilon;
      } else {
        x = tile.right + halfWidth + epsilon;
      }
    }
    return _nudgeXTowardInterior(x, centerY, halfWidth, halfHeight, skin);
  }

  double separateY({
    required double centerX,
    required double centerY,
    required double halfWidth,
    required double halfHeight,
    required double skin,
  }) {
    var y = centerY;
    for (var i = 0; i < 8; i++) {
      final probe = Rect.fromLTRB(
        centerX - halfWidth + skin,
        y - halfHeight,
        centerX + halfWidth - skin,
        y + halfHeight,
      );
      final tiles = _solidTiles(probe);
      if (tiles.isEmpty) {
        return y;
      }
      final tile = _deepestTile(
        tiles,
        penetration: (rect) {
          final up = (y + halfHeight) - rect.top;
          final down = rect.bottom - (y - halfHeight);
          return up < down ? up : down;
        },
      );
      const epsilon = 0.05;
      if (y < tile.center.dy) {
        y = tile.top - halfHeight - epsilon;
      } else {
        y = tile.bottom + halfHeight + epsilon;
      }
    }
    return y;
  }

  Rect _deepestTile(
    List<Rect> tiles, {
    required double Function(Rect tile) penetration,
  }) {
    var best = tiles.first;
    var bestDepth = penetration(best);
    for (var i = 1; i < tiles.length; i++) {
      final depth = penetration(tiles[i]);
      if (depth > bestDepth) {
        best = tiles[i];
        bestDepth = depth;
      }
    }
    return best;
  }

  double _nudgeXTowardInterior(
    double x,
    double centerY,
    double halfWidth,
    double halfHeight,
    double skin,
  ) {
    final mid = level.worldWidth / 2;
    final dir = x < mid ? 1.0 : -1.0;
    var next = x;
    for (var i = 0; i < 16; i++) {
      final probe = Rect.fromLTRB(
        next - halfWidth,
        centerY - halfHeight + skin,
        next + halfWidth,
        centerY + halfHeight - skin,
      );
      if (_solidTiles(probe).isEmpty) {
        return next;
      }
      next += dir * (tileSize / 2);
    }
    return x.clamp(halfWidth, level.worldWidth - halfWidth);
  }

  List<Rect> _solidTiles(Rect hitbox) {
    final tiles = <Rect>[];
    _forEachCell(hitbox, (col, row) {
      if (level.isSolid(col, row)) {
        tiles.add(
          Rect.fromLTWH(col * tileSize, row * tileSize, tileSize, tileSize),
        );
      }
    });
    return tiles;
  }

  GroundSurface surfaceBelow(Rect feet) {
    var surface = GroundSurface.none;
    _forEachCell(feet, (col, row) {
      if (surface == GroundSurface.mud) {
        return;
      }
      final next = surfaceOf(level.tileAt(col, row));
      if (next == GroundSurface.none) {
        return;
      }
      if (next == GroundSurface.mud) {
        surface = GroundSurface.mud;
        return;
      }
      if (next == GroundSurface.ice) {
        surface = GroundSurface.ice;
      } else if (surface == GroundSurface.none) {
        surface = next;
      }
    });
    return surface;
  }

  void _forEachCell(Rect box, void Function(int col, int row) visit) {
    if (box.width <= 0 || box.height <= 0) {
      return;
    }
    final c0 = (box.left / tileSize).floor();
    final c1 = ((box.right - 0.001) / tileSize).floor();
    final r0 = (box.top / tileSize).floor();
    final r1 = ((box.bottom - 0.001) / tileSize).floor();
    for (var row = r0; row <= r1; row++) {
      for (var col = c0; col <= c1; col++) {
        visit(col, row);
      }
    }
  }
}
