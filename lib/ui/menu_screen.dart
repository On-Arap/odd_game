import 'package:flutter/material.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ODD',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: Palette.menuAccent,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Grab every coin. Fastest time wins.',
            style: TextStyle(color: Palette.hudMuted, fontSize: 14),
          ),
          if (total != null) ...[
            const SizedBox(height: 8),
            Text(
              'Total ${formatRunTime(total)}',
              style: const TextStyle(
                color: Palette.hud,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: levels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final level = levels[index];
                return _LevelTile(
                  index: index,
                  level: level,
                  best: _bests.forLevel(level.id),
                  onTap: () => _openLevel(levels, index),
                );
              },
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.menuCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Text(
                (index + 1).toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.menuAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${level.coinCount} coins',
                      style: const TextStyle(
                        color: Palette.hudMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                best == null ? '—' : formatRunTime(best!),
                style: TextStyle(
                  color: best == null ? Palette.hudMuted : Palette.hud,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
