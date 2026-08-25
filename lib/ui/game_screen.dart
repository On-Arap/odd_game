import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:odd/data/best_times_store.dart';
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
    this.playtest = false,
  });

  final List<LevelMap> levels;
  final int index;

  /// Editor try-out: no personal bests, back returns to the caller.
  final bool playtest;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final BestTimesStore _bests = BestTimesStore();
  late int _index;
  late GameInput _input;
  late HudState _hud;
  late OddGame _game;
  bool _recordedWin = false;
  double? _levelBest;
  double? _playtestBest;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _startLevel();
  }

  void _startLevel() {
    final level = widget.levels[_index];
    _recordedWin = false;
    _levelBest = null;
    _input = GameInput();
    _hud = HudState()..addListener(_onHudChanged);
    _game = OddGame(
      level: level,
      input: _input,
      hud: _hud,
    );
    if (!widget.playtest) {
      unawaited(_loadLevelBest());
    }
  }

  Future<void> _loadLevelBest() async {
    final bests = await _bests.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _levelBest = bests.forLevel(widget.levels[_index].id);
    });
  }

  void _onHudChanged() {
    if (widget.playtest && _hud.won) {
      final time = _hud.elapsed;
      if (_playtestBest == null || time < _playtestBest!) {
        _playtestBest = time;
      }
    }
    unawaited(_ensureRecorded());
  }

  Future<void> _ensureRecorded() async {
    if (widget.playtest || !_hud.won || _recordedWin) {
      return;
    }
    _recordedWin = true;
    final levelId = widget.levels[_index].id;
    final time = _hud.elapsed;

    // Keep in-memory PB in sync immediately so retry + win overlay stay correct.
    final stored = _storedBestAfterRun(_levelBest, time);
    if (stored != _levelBest && mounted) {
      setState(() => _levelBest = stored);
    } else {
      _levelBest = stored;
    }

    await _bests.record(levelId, time);
  }

  /// Mirrors [BestTimes.record] for the current level's stored time.
  double? _storedBestAfterRun(double? current, double runTime) {
    if (current == null || runTime < current) {
      return runTime;
    }
    return current;
  }

  Future<void> _rebuildAt(int index) async {
    await _ensureRecorded();
    _hud
      ..removeListener(_onHudChanged)
      ..dispose();
    setState(() {
      _index = index;
      _startLevel();
    });
  }

  @override
  void dispose() {
    _hud
      ..removeListener(_onHudChanged)
      ..dispose();
    super.dispose();
  }

  void _leave() {
    Navigator.of(context).pop(widget.playtest ? _playtestBest : null);
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
            backLabel: widget.playtest ? 'EDITOR' : 'MENU',
            onBack: () async {
              await _ensureRecorded();
              if (context.mounted) {
                _leave();
              }
            },
            onRestart: () async {
              await _ensureRecorded();
              _recordedWin = false;
              _game.queueRestart();
            },
          ),
          ListenableBuilder(
            listenable: _hud,
            builder: (context, _) {
              if (!_hud.won) {
                return const SizedBox.shrink();
              }
              return WinOverlay(
                time: _hud.elapsed,
                personalBest: widget.playtest ? null : _levelBest,
                showPersonalBest: !widget.playtest,
                authorTime: widget.playtest
                    ? null
                    : widget.levels[_index].authorTime,
                menuLabel: widget.playtest ? 'EDITOR' : 'MENU',
                onRetry: () async {
                  await _ensureRecorded();
                  _recordedWin = false;
                  _game.queueRestart();
                },
                onNext: hasNext
                    ? () async {
                        await _ensureRecorded();
                        _rebuildAt(_index + 1);
                      }
                    : null,
                onMenu: () async {
                  await _ensureRecorded();
                  if (context.mounted) {
                    _leave();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
