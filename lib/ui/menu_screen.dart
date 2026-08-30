import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/best_times_store.dart';
import 'package:odd/data/level_repository.dart';
import 'package:odd/data/tutorial_store.dart';
import 'package:odd/ui/tutorial.dart';
import 'package:odd/domain/best_times.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/domain/medals.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/ui/game_screen.dart';
import 'package:odd/ui/sprite_sheet_animation.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<LevelMap>? _levels;
  LevelMap? _daily;
  Object? _error;
  BestTimes _bests = const BestTimes({});
  int _tutorialLvl = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Charge les maps bundle, la daily map, et les PB.
  Future<void> _load() async {
    try {
      final repo = LevelRepository();
      final levels = await repo.loadAll();
      final daily = await repo.loadDaily();
      final bests = await BestTimesStore().load();
      final tutorialLvl = await TutorialStore().load();
      if (!mounted) {
        return;
      }
      setState(() {
        _levels = levels;
        _daily = daily;
        _bests = bests;
        _tutorialLvl = tutorialLvl;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    }
  }

  bool get _tutorialLocksMaps => Tutorial.locksMaps(_tutorialLvl);

  /// Ouvre le niveau puis rafraîchit les temps au retour.
  Future<void> _openLevel(
    List<LevelMap> levels,
    int index, {
    bool showRunTutorial = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          levels: levels,
          index: index,
          showRunTutorial: showRunTutorial,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    final bests = await BestTimesStore().load();
    final tutorialLvl = await TutorialStore().load();
    if (!mounted) {
      return;
    }
    setState(() {
      _bests = bests;
      _tutorialLvl = tutorialLvl;
    });
  }

  Future<void> _openCampaign(List<LevelMap> levels, int index) async {
    if (_tutorialLocksMaps) {
      if (index != 0) {
        return;
      }
      await _openLevel([levels.first], 0, showRunTutorial: true);
      return;
    }
    await _openLevel(levels, index);
  }

  Future<void> _openDaily(LevelMap daily) async {
    if (_tutorialLocksMaps) {
      return;
    }
    await _openLevel([daily], 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: _body()));
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppString.mapsLoadError(_error!),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final levels = _levels;
    final daily = _daily;
    if (levels == null || daily == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = _bests.totalFor(levels.map((level) => level.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const tileGap = 8.0;
          const listTop = 24.0;
          const listBottom = 8.0;
          final listHeight = constraints.maxHeight - listTop - listBottom;
          final filledTileHeight =
              (listHeight - (levels.length - 1) * tileGap) / levels.length;
          final tileHeight = filledTileHeight.clamp(56.0, 80.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: LayoutBuilder(
                  builder: (context, leftBox) {
                    const leftInset = 12.0;
                    const dailyExtraWidth = 40.0;
                    final dailyTileWidth =
                        leftBox.maxWidth - leftInset + dailyExtraWidth;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        leftInset,
                        32,
                        0,
                        listBottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Brand(total: total),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: dailyTileWidth,
                              height: tileHeight,
                              child: _LevelTile(
                                level: daily,
                                backgroundLabel: AppString.dailyMap,
                                title: daily.name,
                                best: _bests.forLevel(daily.id),
                                locked: _tutorialLocksMaps,
                                onTap: () => _openDaily(daily),
                              ),
                            ),
                          ),
                          const SizedBox(height: tileGap),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: listTop,
                    bottom: listBottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < levels.length; index++) ...[
                          if (index > 0) const SizedBox(height: tileGap),
                          SizedBox(
                            height: tileHeight,
                            child: _LevelTile(
                              index: index,
                              level: levels[index],
                              best: _bests.forLevel(levels[index].id),
                              locked: _tutorialLocksMaps && index > 0,
                              onTap: () => _openCampaign(levels, index),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
              Text(
                AppString.appTitle,
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
        Text(
          AppString.menuTagline,
          style: TextStyle(color: Palette.hudMuted, fontSize: 15),
        ),
        if (total != null) ...[
          const SizedBox(height: 14),
          Text(
            AppString.totalTime(formatRunTime(total!)),
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
    required this.level,
    required this.best,
    required this.onTap,
    this.index,
    this.backgroundLabel,
    this.title,
    this.locked = false,
  });

  final int? index;
  final String? backgroundLabel;
  final LevelMap level;
  final String? title;
  final double? best;
  final bool locked;
  final VoidCallback onTap;

  String? get _background {
    if (backgroundLabel != null) {
      return backgroundLabel;
    }
    if (index == null) {
      return null;
    }
    return (index! + 1).toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final background = _background;
    final label = title ?? level.name;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked ? null : onTap,
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
                if (background != null)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          background,
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
                if (locked)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xAA0A0B10)),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 10, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (locked) ...[
                          const Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: Palette.hudMuted,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: locked ? Palette.hudMuted : Palette.hud,
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
                              _TileAwards(level: level, best: best),
                              const SizedBox(width: 8),
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

class _TileAwards extends StatelessWidget {
  const _TileAwards({required this.level, required this.best});

  final LevelMap level;
  final double? best;

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AwardSlot(
          size: size,
          filled: medalEarned(best, level.bronzeTime),
          asset: GameSprites.bundle(GameSprites.medalCopper),
        ),
        const SizedBox(width: 4),
        _AwardSlot(
          size: size,
          filled: medalEarned(best, level.silverTime),
          asset: GameSprites.bundle(GameSprites.medalSilver),
        ),
        const SizedBox(width: 4),
        _AwardSlot(
          size: size,
          filled: medalEarned(best, level.goldTime),
          asset: GameSprites.bundle(GameSprites.medalGold),
        ),
        const SizedBox(width: 8),
        _AwardSlot(
          size: size,
          filled: medalEarned(best, level.authorTime),
          asset: GameSprites.bundle(GameSprites.authorGem),
          frameCount: 5,
        ),
      ],
    );
  }
}

class _AwardSlot extends StatelessWidget {
  const _AwardSlot({
    required this.size,
    required this.filled,
    required this.asset,
    this.frameCount = 8,
  });

  final double size;
  final bool filled;
  final String asset;
  final int frameCount;

  @override
  Widget build(BuildContext context) {
    final empty = _EmptyAward(size: size);
    if (!filled) {
      return empty;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        empty,
        SpriteSheetAnimation(asset: asset, size: size, frameCount: frameCount),
      ],
    );
  }
}

class _EmptyAward extends StatelessWidget {
  const _EmptyAward({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x33000000),
        border: Border.all(color: Palette.hudMuted.withValues(alpha: 0.45)),
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
        hasTime ? formatRunTime(best!) : AppString.noTime,
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
