import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/auth_store.dart';
import 'package:odd/data/best_times_store.dart';
import 'package:odd/data/leaderboard_store.dart';
import 'package:odd/data/level_repository.dart';
import 'package:odd/data/supabase_config.dart';
import 'package:odd/data/tutorial_store.dart';
import 'package:odd/domain/best_times.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/domain/medals.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/ui/game_dialog_card.dart';
import 'package:odd/ui/game_screen.dart';
import 'package:odd/ui/leaderboard_list.dart';
import 'package:odd/ui/nickname_dialog.dart';
import 'package:odd/ui/sprite_sheet_animation.dart';
import 'package:odd/ui/tutorial.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  List<LevelMap>? _levels;
  LevelMap? _daily;
  Object? _error;
  BestTimes _bests = const BestTimes({});
  int _tutorialLvl = 0;
  int _selectedIndex = 0;
  var _dailySelected = false;
  int _leaderboardRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      unawaited(_refreshMapsIfChanged());
    }
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
        _bests = bests;
        _tutorialLvl = tutorialLvl;
        _error = null;
        _applyMaps(levels, daily);
      });
      unawaited(_ensureOnlineProfile());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    }
  }

  bool get _tutorialLocksMaps => Tutorial.locksMaps(_tutorialLvl);

  Future<void> _ensureOnlineProfile() async {
    if (!SupabaseConfig.isReady || !mounted) {
      return;
    }
    try {
      final auth = const AuthStore();
      await auth.ensureSession();
      final name = await auth.displayName();
      if (!mounted) {
        return;
      }
      if (name == null && (ModalRoute.of(context)?.isCurrent ?? false)) {
        final saved = await showNicknameDialog(context);
        if (saved && mounted) {
          await const LeaderboardStore().syncLocalBests(_bests);
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppString.onlineProfileError(error))),
      );
    }
  }

  /// Ouvre le niveau puis rafraîchit temps + maps (si le catalogue DB a changé).
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
    final maps = await _catalogIfChanged();
    if (!mounted) {
      return;
    }
    setState(() {
      _bests = bests;
      _tutorialLvl = tutorialLvl;
      _leaderboardRevision++;
      if (maps != null) {
        _applyMaps(maps.levels, maps.daily);
      }
    });
  }

  List<String> get _campaignIds => [
    for (final level in _levels ?? const <LevelMap>[]) level.id,
  ];

  Future<({List<LevelMap> levels, LevelMap daily})?> _catalogIfChanged() {
    return LevelRepository().loadIfCatalogChanged(
      campaignIds: _campaignIds,
      dailyId: _daily?.id,
    );
  }

  Future<void> _refreshMapsIfChanged() async {
    final maps = await _catalogIfChanged();
    if (!mounted || maps == null) {
      return;
    }
    setState(() => _applyMaps(maps.levels, maps.daily));
  }

  void _applyMaps(List<LevelMap> levels, LevelMap daily) {
    final selectedId =
        !_dailySelected &&
            _levels != null &&
            _levels!.isNotEmpty &&
            _selectedIndex >= 0 &&
            _selectedIndex < _levels!.length
        ? _levels![_selectedIndex].id
        : null;
    _levels = levels;
    _daily = daily;
    if (selectedId != null) {
      final index = levels.indexWhere((level) => level.id == selectedId);
      _selectedIndex = index >= 0 ? index : 0;
      return;
    }
    if (_selectedIndex >= levels.length) {
      _selectedIndex = 0;
    }
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

  void _selectCampaign(int index) {
    setState(() {
      _selectedIndex = index;
      _dailySelected = false;
    });
  }

  void _selectDaily() {
    setState(() => _dailySelected = true);
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
    final selected = _dailySelected ? daily : levels[_selectedIndex];
    final selectedLocked =
        _tutorialLocksMaps && (_dailySelected || _selectedIndex > 0);
    final selectedLabel = _dailySelected
        ? AppString.dailyMap
        : AppString.levelNumber(_selectedIndex);
    final showPlayMask = _tutorialLvl == 0;
    final total = _bests.totalFor(levels.map((level) => level.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
              child: LayoutBuilder(
                builder: (context, leftBox) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: leftBox.maxHeight * 0.42,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topLeft,
                                    child: SizedBox(
                                      width: leftBox.maxWidth,
                                      child: _Brand(total: total),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  selectedLabel,
                                  style: const TextStyle(
                                    color: Palette.menuAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  selected.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Palette.hud,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: LeaderboardList(
                                    key: ValueKey(
                                      '${selected.id}-$_leaderboardRevision',
                                    ),
                                    mapId: selected.id,
                                    revision: _leaderboardRevision,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                            if (showPlayMask)
                              const _HomeMask(key: Key('tutorial-home-mask')),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: showPlayMask
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.menuAccent.withValues(
                                      alpha: 0.55,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                            : const BoxDecoration(),
                        child: GameDialogButton(
                          label: AppString.playLevel,
                          enabled: !selectedLocked,
                          onTap: () {
                            if (_dailySelected) {
                              _openDaily(daily);
                              return;
                            }
                            _openCampaign(levels, _selectedIndex);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: levels.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        return _MapSquareTile(
                          key: ValueKey('campaign-tile-$index'),
                          level: levels[index],
                          best: _bests.forLevel(levels[index].id),
                          selected: !_dailySelected && index == _selectedIndex,
                          locked: _tutorialLocksMaps && index > 0,
                          onTap: () => _selectCampaign(index),
                        );
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 72,
                      child: _LevelTile(
                        level: daily,
                        backgroundLabel: AppString.dailyMap,
                        title: daily.name,
                        best: _bests.forLevel(daily.id),
                        selected: _dailySelected,
                        locked: _tutorialLocksMaps,
                        onTap: _selectDaily,
                      ),
                    ),
                  ],
                ),
                if (showPlayMask) const _HomeMask(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMask extends StatelessWidget {
  const _HomeMask({super.key});

  @override
  Widget build(BuildContext context) {
    return const AbsorbPointer(child: ColoredBox(color: Color(0xB3000000)));
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

class _MapSquareTile extends StatelessWidget {
  const _MapSquareTile({
    super.key,
    required this.level,
    required this.best,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final LevelMap level;
  final double? best;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final award = bestAwardFor(
      best: best,
      bronzeTime: level.bronzeTime,
      silverTime: level.silverTime,
      goldTime: level.goldTime,
      authorTime: level.authorTime,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF161821),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Palette.menuAccent : const Color(0x18FFFFFF),
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (locked)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xAA0A0B10)),
                  ),
                LayoutBuilder(
                  builder: (context, tileBox) {
                    final medalSize = (tileBox.maxWidth * 0.38).clamp(
                      16.0,
                      26.0,
                    );
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: _AwardSlot(
                                size: medalSize,
                                filled: award != BestAward.none,
                                asset: _awardAsset(award),
                                frameCount: award == BestAward.author ? 5 : 8,
                              ),
                            ),
                          ),
                          _TimeChip(best: best, compact: true),
                        ],
                      ),
                    );
                  },
                ),
                if (locked)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Palette.hudMuted,
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

String _awardAsset(BestAward award) {
  return switch (award) {
    BestAward.bronze => GameSprites.bundle(GameSprites.medalCopper),
    BestAward.silver => GameSprites.bundle(GameSprites.medalSilver),
    BestAward.gold => GameSprites.bundle(GameSprites.medalGold),
    BestAward.author => GameSprites.bundle(GameSprites.authorGem),
    BestAward.none => GameSprites.bundle(GameSprites.medalCopper),
  };
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.best,
    required this.onTap,
    this.backgroundLabel,
    this.title,
    this.selected = false,
    this.locked = false,
  });

  final String? backgroundLabel;
  final LevelMap level;
  final String? title;
  final double? best;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  String? get _background => backgroundLabel;

  @override
  Widget build(BuildContext context) {
    final background = _background;
    final label = title ?? level.name;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF161821),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Palette.menuAccent : const Color(0x18FFFFFF),
              width: selected ? 2 : 1,
            ),
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
  const _TimeChip({required this.best, this.compact = false});

  final double? best;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasTime = best != null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: hasTime ? const Color(0xFF222433) : const Color(0xFF1B1D28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasTime ? formatRunTime(best!) : AppString.noTime,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasTime ? Palette.hud : Palette.hudMuted,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 10 : 13,
          height: 1.1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
