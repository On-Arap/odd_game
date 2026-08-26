import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/data/best_times_store.dart';
import 'package:odd/data/level_repository.dart';
import 'package:odd/domain/best_times.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/ui/game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<LevelMap>? _levels;
  Object? _error;
  BestTimes _bests = const BestTimes({});

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Charge les maps bundle + les PB.
  Future<void> _load() async {
    try {
      final levels = await LevelRepository().loadAll();
      final bests = await BestTimesStore().load();
      if (!mounted) {
        return;
      }
      setState(() {
        _levels = levels;
        _bests = bests;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    }
  }

  /// Ouvre le niveau puis rafraîchit les temps au retour.
  Future<void> _openLevel(List<LevelMap> levels, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          levels: levels,
          index: index,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    final bests = await BestTimesStore().load();
    if (!mounted) {
      return;
    }
    setState(() => _bests = bests);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load maps.\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final levels = _levels;
    if (levels == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = _bests.totalFor(levels.map((level) => level.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 32, 20, 0),
                child: _Brand(total: total),
              ),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Column(
                children: [
                  for (var index = 0; index < levels.length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    Expanded(
                      child: _LevelTile(
                        index: index,
                        level: levels[index],
                        best: _bests.forLevel(levels[index].id),
                        onTap: () => _openLevel(levels, index),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.total});

  final double? total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ODD',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: Palette.menuAccent,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: _MenuPenguin(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Grab every coin. Fastest time wins.',
          style: TextStyle(color: Palette.hudMuted, fontSize: 15),
        ),
        if (total != null) ...[
          const SizedBox(height: 14),
          Text(
            'Total ${formatRunTime(total!)}',
            style: const TextStyle(
              color: Palette.hud,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuPenguin extends StatefulWidget {
  const _MenuPenguin();

  @override
  State<_MenuPenguin> createState() => _MenuPenguinState();
}

class _MenuPenguinState extends State<_MenuPenguin> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await rootBundle.load('assets/sprites/player/penguin.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _image = frame.image);
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const display = 56.0;
    final image = _image;
    if (image == null) {
      return const SizedBox(width: display, height: display);
    }
    return CustomPaint(
      size: const Size(display, display),
      painter: _PenguinPainter(image),
    );
  }
}

class _PenguinPainter extends CustomPainter {
  _PenguinPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      const Rect.fromLTWH(8, 16, 16, 16),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _PenguinPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.index,
    required this.level,
    required this.best,
    required this.onTap,
  });

  final int index;
  final LevelMap level;
  final double? best;
  final VoidCallback onTap;

  bool get _beatAuthor =>
      best != null && level.authorTime != null && best! <= level.authorTime!;

  @override
  Widget build(BuildContext context) {
    final number = (index + 1).toString().padLeft(2, '0');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF161821),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x18FFFFFF)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        number,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -2,
                          color: Color(0xFF3A3D4A),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 10, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            level.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Palette.hud,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_beatAuthor) ...[
                                const Icon(
                                  Icons.emoji_events,
                                  size: 18,
                                  color: Palette.coin,
                                ),
                                const SizedBox(width: 8),
                              ],
                              _TimeChip(best: best),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.best});

  final double? best;

  @override
  Widget build(BuildContext context) {
    final hasTime = best != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasTime ? const Color(0xFF222433) : const Color(0xFF1B1D28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasTime ? formatRunTime(best!) : '—',
        style: TextStyle(
          color: hasTime ? Palette.hud : Palette.hudMuted,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1.1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
