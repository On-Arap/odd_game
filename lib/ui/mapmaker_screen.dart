import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/ui/game_screen.dart';
import 'package:odd/ui/mapmaker_preview.dart';

/// Fills the inclusive rectangle from (col0, row0) to (col1, row1).
List<String> paintGridRect(
  List<String> grid, {
  required int col0,
  required int row0,
  required int col1,
  required int row1,
  required String tile,
}) {
  if (grid.isEmpty) {
    return grid;
  }
  final cols = grid.first.length;
  final rows = grid.length;
  if (cols == 0 || rows == 0) {
    return grid;
  }

  var left = col0 < col1 ? col0 : col1;
  var right = col0 < col1 ? col1 : col0;
  var top = row0 < row1 ? row0 : row1;
  var bottom = row0 < row1 ? row1 : row0;
  if (right < 0 || bottom < 0 || left >= cols || top >= rows) {
    return grid;
  }
  left = left.clamp(0, cols - 1);
  right = right.clamp(0, cols - 1);
  top = top.clamp(0, rows - 1);
  bottom = bottom.clamp(0, rows - 1);

  var changed = false;
  final next = List<String>.of(grid);
  for (var row = top; row <= bottom; row++) {
    final line = next[row];
    final buffer = StringBuffer();
    for (var col = 0; col < cols; col++) {
      if (col >= left && col <= right) {
        buffer.write(tile);
        if (line[col] != tile) {
          changed = true;
        }
      } else {
        buffer.write(line[col]);
      }
    }
    next[row] = buffer.toString();
  }
  return changed ? next : grid;
}

class MapMakerTile {
  const MapMakerTile({
    required this.code,
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String code;
  final String label;
  final Color color;
  final Color foreground;
}

const mapMakerTiles = [
  MapMakerTile(
    code: TileCodes.empty,
    label: 'Empty',
    color: Color(0xFF0E0F16),
    foreground: Palette.hudMuted,
  ),
  MapMakerTile(
    code: TileCodes.solid,
    label: 'Solid',
    color: Palette.snowFill,
    foreground: Palette.hud,
  ),
  MapMakerTile(
    code: TileCodes.ice,
    label: 'Ice',
    color: Palette.iceA,
    foreground: Color(0xFF0E0F16),
  ),
  MapMakerTile(
    code: TileCodes.mud,
    label: 'Mud',
    color: Palette.mudA,
    foreground: Palette.hud,
  ),
  MapMakerTile(
    code: TileCodes.player,
    label: 'Player',
    color: Palette.player,
    foreground: Palette.playerEye,
  ),
  MapMakerTile(
    code: TileCodes.coin,
    label: 'Coin',
    color: Palette.coin,
    foreground: Color(0xFF0E0F16),
  ),
];

class MapMakerScreen extends StatefulWidget {
  const MapMakerScreen({super.key, this.assetsFuture});

  /// For tests. Defaults to loading game sprites from assets.
  final Future<MapMakerAssets>? assetsFuture;

  @override
  State<MapMakerScreen> createState() => _MapMakerScreenState();
}

class _MapMakerScreenState extends State<MapMakerScreen> {
  static const _minSize = 1;

  final _widthController = TextEditingController(text: '32');
  final _heightController = TextEditingController(text: '18');
  final _idController = TextEditingController(text: 'new_map');
  final _nameController = TextEditingController(text: 'New Map');

  late List<String> _grid;
  late Future<MapMakerAssets> _assetsFuture;
  MapMakerAssets? _assets;
  String _selected = TileCodes.solid;
  int _cols = 32;
  int _rows = 18;
  double? _authorTime;

  @override
  void initState() {
    super.initState();
    _assetsFuture = widget.assetsFuture ?? MapMakerAssets.load();
    _grid = _emptyGrid(_cols, _rows);
    _assetsFuture.then((assets) {
      if (!mounted) {
        return;
      }
      setState(() => _assets = assets);
    }).catchError((Object error) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not load sprites: $error');
    });
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  List<String> _emptyGrid(int cols, int rows) {
    return List.generate(rows, (_) => TileCodes.empty * cols);
  }

  void _applySize() {
    final cols = int.tryParse(_widthController.text);
    final rows = int.tryParse(_heightController.text);
    if (cols == null ||
        rows == null ||
        cols < _minSize ||
        rows < _minSize) {
      _showMessage('Width and height must be positive numbers.');
      return;
    }

    final next = _emptyGrid(cols, rows);
    for (var row = 0; row < rows && row < _rows; row++) {
      final copyLen = cols < _cols ? cols : _cols;
      next[row] = _grid[row].substring(0, copyLen).padRight(cols, TileCodes.empty);
    }

    setState(() {
      _cols = cols;
      _rows = rows;
      _grid = next;
      _authorTime = null;
    });
  }

  void _paintRect(int col0, int row0, int col1, int row1) {
    final next = paintGridRect(
      _grid,
      col0: col0,
      row0: row0,
      col1: col1,
      row1: row1,
      tile: _selected,
    );
    if (identical(next, _grid)) {
      return;
    }
    setState(() {
      _grid = next;
      _authorTime = null;
    });
  }

  String _buildJson() {
    final payload = <String, Object>{
      'format': 1,
      'id': _idController.text.trim().isEmpty
          ? 'new_map'
          : _idController.text.trim(),
      'name': _nameController.text.trim().isEmpty
          ? 'New Map'
          : _nameController.text.trim(),
      'tileSize': 16,
      if (_authorTime != null) 'author_time': _jsonAuthorTime(_authorTime!),
      'grid': _grid,
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  static double _jsonAuthorTime(double seconds) {
    return (seconds * 100).round() / 100;
  }

  String? _loadFromJson(String source) {
    try {
      final decoded = jsonDecode(source.trim());
      if (decoded is! Map<String, dynamic>) {
        return 'Expected a JSON object.';
      }

      final gridRaw = decoded['grid'];
      if (gridRaw is! List || gridRaw.isEmpty) {
        return 'Missing a non-empty "grid".';
      }

      final grid = gridRaw.map((row) {
        if (row is! String) {
          throw FormatException('Grid rows must be strings.');
        }
        return row;
      }).toList();

      final cols = grid.first.length;
      final rows = grid.length;
      if (cols == 0) {
        return 'Grid rows cannot be empty.';
      }
      if (cols < _minSize || rows < _minSize) {
        return 'Grid width and height must be at least $_minSize.';
      }

      for (var row = 0; row < rows; row++) {
        if (grid[row].length != cols) {
          return 'Row $row has uneven width.';
        }
        for (var col = 0; col < cols; col++) {
          final cell = grid[row][col];
          if (!_isValidCell(cell)) {
            return 'Unknown tile "$cell" at ($col, $row). Use . # I M P C.';
          }
        }
      }

      final id = decoded['id'];
      final name = decoded['name'];
      final authorTimeRaw = decoded['author_time'];
      double? authorTime;
      if (authorTimeRaw is num && authorTimeRaw >= 0) {
        authorTime = authorTimeRaw.toDouble();
      }

      setState(() {
        _grid = grid;
        _cols = cols;
        _rows = rows;
        _authorTime = authorTime;
        _widthController.text = cols.toString();
        _heightController.text = rows.toString();
        if (id is String && id.isNotEmpty) {
          _idController.text = id;
        }
        if (name is String && name.isNotEmpty) {
          _nameController.text = name;
        }
      });
      return null;
    } on FormatException catch (error) {
      return error.message;
    } catch (error) {
      return 'Invalid JSON.';
    }
  }

  bool _isValidCell(String cell) {
    return cell == TileCodes.empty ||
        cell == TileCodes.solid ||
        cell == TileCodes.ice ||
        cell == TileCodes.mud ||
        cell == TileCodes.player ||
        cell == TileCodes.coin;
  }

  Future<void> _play() async {
    try {
      final level = LevelMap.parseJson(_buildJson(), file: 'draft.json');
      if (!mounted) {
        return;
      }
      final time = await Navigator.of(context).push<double?>(
        MaterialPageRoute<double?>(
          builder: (_) => GameScreen(
            levels: [level],
            index: 0,
            playtest: true,
          ),
        ),
      );
      if (!mounted || time == null) {
        return;
      }
      setState(() {
        if (_authorTime == null || time < _authorTime!) {
          _authorTime = time;
        }
      });
    } on FormatException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showExportDialog() async {
    final loaded = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ExportDialog(onLoad: _loadFromJson);
      },
    );
    if (loaded == true && mounted) {
      _showMessage('Map loaded.');
    }
  }

  Future<void> _generate() async {
    if (_authorTime == null) {
      _showMessage('Play and complete the map before generating.');
      return;
    }
    final json = _buildJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Map JSON'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(json, style: const TextStyle(fontSize: 12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON copied to clipboard')),
                  );
                }
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Maker'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            child: const Text('Back to menu'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _sizeField(label: 'Width', controller: _widthController),
                _sizeField(label: 'Height', controller: _heightController),
                FilledButton(onPressed: _applySize, child: const Text('Apply')),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Map id',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Map name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tile in mapMakerTiles)
                  _PaletteTile(
                    tile: tile,
                    selected: _selected == tile.code,
                    onTap: () => setState(() => _selected = tile.code),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.hudMuted),
                  color: Palette.background,
                ),
                child: _ScrollablePreview(
                  child: MapMakerPreviewGrid(
                    cols: _cols,
                    rows: _rows,
                    grid: _grid,
                    assets: _assets,
                    brushColor: mapMakerTiles
                        .firstWhere((tile) => tile.code == _selected)
                        .color,
                    onPaintRect: _paintRect,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _authorTime == null
                      ? 'Complete the map in Play to generate JSON.'
                      : 'Validated ${formatRunTime(_authorTime!)}',
                  style: TextStyle(
                    color: _authorTime == null
                        ? Palette.hudMuted
                        : Palette.hud,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _footerButton(
                      label: 'Export',
                      onPressed: _showExportDialog,
                      filled: false,
                    ),
                    _footerButton(
                      label: 'Play',
                      onPressed: _play,
                      filled: true,
                    ),
                    _footerButton(
                      label: 'Generate',
                      onPressed: _authorTime == null ? null : _generate,
                      filled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sizeField({
    required String label,
    required TextEditingController controller,
  }) {
    return SizedBox(
      width: 96,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _applySize(),
      ),
    );
  }

  Widget _footerButton({
    required String label,
    required VoidCallback? onPressed,
    required bool filled,
  }) {
    final style = filled
        ? FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        : OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class _ScrollablePreview extends StatefulWidget {
  const _ScrollablePreview({required this.child});

  final Widget child;

  @override
  State<_ScrollablePreview> createState() => _ScrollablePreviewState();
}

class _ScrollablePreviewState extends State<_ScrollablePreview> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _vertical,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vertical,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.onLoad});

  final String? Function(String source) onLoad;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _jsonController = TextEditingController();

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _export() {
    final error = widget.onLoad(_jsonController.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('export-json-field'),
                controller: _jsonController,
                maxLines: 14,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Paste map JSON here…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _export,
                child: const Text('Export'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.tile,
    required this.selected,
    required this.onTap,
  });

  final MapMakerTile tile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tile.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Palette.coin : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          '${tile.label} (${tile.code})',
          style: TextStyle(
            color: tile.foreground,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
