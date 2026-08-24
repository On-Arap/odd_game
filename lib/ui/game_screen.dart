import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/odd_game.dart';
import 'package:odd/ui/overlays/hud_overlay.dart';
import 'package:odd/ui/overlays/touch_controls.dart';
import 'package:odd/ui/overlays/win_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levels,
    required this.index,
  });

  final List<LevelMap> levels;
  final int index;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int _index;
  late GameInput _input;
  late HudState _hud;
  late OddGame _game;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _startLevel();
  }

  void _startLevel() {
    final level = widget.levels[_index];
    _input = GameInput();
    _hud = HudState();
    _game = OddGame(
      level: level,
      input: _input,
      hud: _hud,
    );
  }

  void _rebuildAt(int index) {
    _hud.dispose();
    setState(() {
      _index = index;
      _startLevel();
    });
  }

  @override
  void dispose() {
    _hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = _index + 1 < widget.levels.length;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(
            key: ValueKey(widget.levels[_index].id),
            game: _game,
            autofocus: true,
          ),
          TouchControls(input: _input),
          HudOverlay(
            hud: _hud,
            onBack: () => Navigator.of(context).pop(),
            onRestart: _game.queueRestart,
          ),
          ListenableBuilder(
            listenable: _hud,
            builder: (context, _) {
              if (!_hud.won) {
                return const SizedBox.shrink();
              }
              return WinOverlay(
                time: _hud.elapsed,
                onRetry: _game.queueRestart,
                onNext: hasNext ? () => _rebuildAt(_index + 1) : null,
                onMenu: () => Navigator.of(context).pop(),
              );
            },
          ),
        ],
      ),
    );
  }
}
