import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/ui/mapmaker_preview.dart';

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
    });
  }

  void _paintCell(int col, int row) {
    if (col < 0 || col >= _cols || row < 0 || row >= _rows) {
      return;
    }
    final line = _grid[row];
    if (line[col] == _selected) {
      return;
    }
    setState(() {
      final next = List<String>.from(_grid);
      next[row] = line.replaceRange(col, col + 1, _selected);
      _grid = next;
    });
  }

  String _buildJson() {
    final payload = {
      'format': 1,
      'id': _idController.text.trim().isEmpty
          ? 'new_map'
          : _idController.text.trim(),
      'name': _nameController.text.trim().isEmpty
          ? 'New Map'
          : _nameController.text.trim(),
      'tileSize': 16,
      'grid': _grid,
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
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

      setState(() {
        _grid = grid;
        _cols = cols;
        _rows = rows;
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
                    onPaint: _paintCell,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showExportDialog,
                    child: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _generate,
                    child: const Text('Generate'),
                  ),
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
