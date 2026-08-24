import 'package:flutter/material.dart';
import 'package:odd/data/level_repository.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/ui/game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final Future<List<LevelMap>> _levels = LevelRepository().loadAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<LevelMap>>(
          future: _levels,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load maps.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final levels = snapshot.data!;
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
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GameScreen(
                                  levels: levels,
                                  index: index,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.index,
    required this.level,
    required this.onTap,
  });

  final int index;
  final LevelMap level;
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
                child: Text(
                  level.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${level.coinCount} coins',
                style: const TextStyle(color: Palette.hudMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
