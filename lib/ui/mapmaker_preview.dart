import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/config.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/world/ice_autotile.dart';
import 'package:odd/game/world/snow_autotile.dart';

class MapMakerAssets {
  const MapMakerAssets({
    required this.snow,
    required this.coin,
    required this.player,
  });

  final ui.Image snow;
  final ui.Image coin;
  final ui.Image player;

  static Future<MapMakerAssets> load() async {
    final results = await Future.wait<ui.Image>([
      _loadImage('assets/sprites/tilesets/tileset_snow.png'),
      _loadImage('assets/sprites/objects/coin_gold.png'),
      _loadImage('assets/sprites/player/penguin.png'),
    ]);
    return MapMakerAssets(
      snow: results[0],
      coin: results[1],
      player: results[2],
    );
  }

  static Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<MapMakerAssets> placeholder() async {
    final image = await _blankImage();
    return MapMakerAssets(snow: image, coin: image, player: image);
  }

  static Future<ui.Image> _blankImage() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(const Color(0xFF000000), BlendMode.src);
    final picture = recorder.endRecording();
    return picture.toImage(1, 1);
  }
}

LevelMap previewLevel(List<String> grid) {
  return LevelMap(
    format: 1,
    id: 'preview',
    name: 'Preview',
    file: 'preview.json',
    tileSize: 16,
    grid: grid,
    spawn: const GridPos(0, 0),
    coins: const [],
  );
}

/// Fast grid lines + checker so the editor is usable before sprites finish.
class MapGridLinesPainter extends CustomPainter {
  MapGridLinesPainter({required this.cols, required this.rows});

  final int cols;
  final int rows;

  static const _tile = MapMakerPreviewGrid.tileSize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.background);

    final checker = Paint()..color = const Color(0xFF15161F);
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if ((col + row).isOdd) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(col * _tile, row * _tile, _tile, _tile),
          checker,
        );
      }
    }

    final line = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 1;
    for (var col = 0; col <= cols; col++) {
      final x = col * _tile + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, rows * _tile), line);
    }
    for (var row = 0; row <= rows; row++) {
      final y = row * _tile + 0.5;
      canvas.drawLine(Offset(0, y), Offset(cols * _tile, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant MapGridLinesPainter oldDelegate) {
    return oldDelegate.cols != cols || oldDelegate.rows != rows;
  }
}

abstract final class MapPreviewRenderer {
  static const _tile = MapMakerPreviewGrid.tileSize;

  static Future<ui.Image> rasterize({
    required List<String> grid,
    required MapMakerAssets assets,
  }) async {
    final level = previewLevel(grid);
    final width = (level.cols * _tile).ceil();
    final height = (level.rows * _tile).ceil();
    if (width == 0 || height == 0) {
      return MapMakerAssets._blankImage();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var row = 0; row < level.rows; row++) {
      for (var col = 0; col < level.cols; col++) {
        _paintCell(canvas, level, grid, assets, col, row);
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  static void _paintCell(
    Canvas canvas,
    LevelMap level,
    List<String> grid,
    MapMakerAssets assets,
    int col,
    int row,
  ) {
    final cell = grid[row][col];
    final dst = Rect.fromLTWH(col * _tile, row * _tile, _tile, _tile);

    switch (cell) {
      case TileCodes.solid:
        _paintSnow(canvas, level, assets, col, row, dst);
      case TileCodes.ice:
        _paintIce(canvas, level, assets, col, row, dst);
      case TileCodes.mud:
        canvas.drawRect(
          dst,
          Paint()..color = Palette.tile(cell, col, row),
        );
      case TileCodes.coin:
        _paintCoin(canvas, assets, col, row);
      case TileCodes.player:
        _paintPlayer(canvas, assets, col, row);
      case TileCodes.empty:
        break;
    }
  }

  static void _paintSnow(
    Canvas canvas,
    LevelMap level,
    MapMakerAssets assets,
    int col,
    int row,
    Rect dst,
  ) {
    final src = SnowAutotile.src(level, col, row);
    if (src == null) {
      canvas.drawRect(dst, Paint()..color = Palette.snowFill);
      return;
    }
    _drawSprite(canvas, assets.snow, src.x, src.y, dst);
  }

  static void _paintIce(
    Canvas canvas,
    LevelMap level,
    MapMakerAssets assets,
    int col,
    int row,
    Rect dst,
  ) {
    canvas.drawRect(dst, Paint()..color = Palette.snowFill);
    final src = IceAutotile.src(level, col, row);
    _drawSprite(canvas, assets.snow, src.x, src.y, dst);
  }

  static void _paintCoin(Canvas canvas, MapMakerAssets assets, int col, int row) {
    final dst = Rect.fromCenter(
      center: Offset((col + 0.5) * _tile, (row + 0.5) * _tile),
      width: _tile,
      height: _tile,
    );
    _drawSprite(canvas, assets.coin, 0, 0, dst);
  }

  static void _paintPlayer(Canvas canvas, MapMakerAssets assets, int col, int row) {
    const art = 16.0;
    const insetX = 8.0;
    const insetY = 16.0;
    final dst = Rect.fromCenter(
      center: Offset(
        (col + 0.5) * _tile,
        (row + 1) * _tile - GameConfig.playerHeight / 2,
      ),
      width: GameConfig.playerWidth,
      height: GameConfig.playerHeight,
    );
    _drawSprite(canvas, assets.player, insetX, insetY, dst, art, art);
  }

  static void _drawSprite(
    Canvas canvas,
    ui.Image image,
    double sx,
    double sy,
    Rect dst, [
    double sw = _tile,
    double sh = _tile,
  ]) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(sx, sy, sw, sh),
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}

class MapMakerPreviewGrid extends StatefulWidget {
  const MapMakerPreviewGrid({
    super.key,
    required this.cols,
    required this.rows,
    required this.grid,
    required this.onPaint,
    this.assets,
  });

  final int cols;
  final int rows;
  final List<String> grid;
  final MapMakerAssets? assets;
  final void Function(int col, int row) onPaint;

  static const tileSize = 16.0;

  @override
  State<MapMakerPreviewGrid> createState() => _MapMakerPreviewGridState();
}

class _MapMakerPreviewGridState extends State<MapMakerPreviewGrid> {
  bool _painting = false;
  ui.Image? _spriteLayer;
  int _scheduledGeneration = 0;
  Timer? _rebuildTimer;
  bool _building = false;

  @override
  void initState() {
    super.initState();
    _scheduleRasterize();
  }

  @override
  void didUpdateWidget(covariant MapMakerPreviewGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grid != widget.grid ||
        oldWidget.assets != widget.assets ||
        oldWidget.cols != widget.cols ||
        oldWidget.rows != widget.rows) {
      _scheduleRasterize();
    }
  }

  @override
  void dispose() {
    _rebuildTimer?.cancel();
    _spriteLayer?.dispose();
    super.dispose();
  }

  void _scheduleRasterize() {
    _rebuildTimer?.cancel();
    if (widget.assets == null) {
      setState(() {
        _spriteLayer?.dispose();
        _spriteLayer = null;
        _building = false;
      });
      return;
    }
    final generation = ++_scheduledGeneration;
    _rebuildTimer = Timer(
      const Duration(milliseconds: 16),
      () => _rasterize(generation),
    );
  }

  Future<void> _rasterize(int generation) async {
    final assets = widget.assets;
    if (!mounted || assets == null || generation != _scheduledGeneration) {
      return;
    }
    setState(() => _building = true);

    final image = await MapPreviewRenderer.rasterize(
      grid: widget.grid,
      assets: assets,
    );

    if (!mounted || generation != _scheduledGeneration) {
      image.dispose();
      if (mounted) {
        setState(() => _building = false);
      }
      return;
    }

    setState(() {
      _spriteLayer?.dispose();
      _spriteLayer = image;
      _building = false;
    });
  }

  void _paintAt(Offset local) {
    final col = (local.dx / MapMakerPreviewGrid.tileSize).floor();
    final row = (local.dy / MapMakerPreviewGrid.tileSize).floor();
    widget.onPaint(col, row);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.cols * MapMakerPreviewGrid.tileSize;
    final height = widget.rows * MapMakerPreviewGrid.tileSize;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: MapGridLinesPainter(
              cols: widget.cols,
              rows: widget.rows,
            ),
          ),
          if (_spriteLayer != null)
            RawImage(
              image: _spriteLayer,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          if (_building && _spriteLayer == null)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _painting = true;
              _paintAt(event.localPosition);
            },
            onPointerMove: (event) {
              if (_painting) {
                _paintAt(event.localPosition);
              }
            },
            onPointerUp: (_) => _painting = false,
            onPointerCancel: (_) => _painting = false,
          ),
        ],
      ),
    );
  }
}
