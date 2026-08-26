import 'package:flutter/material.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/palette.dart';

class TouchControls extends StatefulWidget {
  const TouchControls({super.key, required this.input});

  final GameInput input;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  final Set<int> _runPointers = {};
  final Set<int> _jumpPointers = {};

  /// Run maintenu tant qu'au moins un doigt est sur le pad.
  void _syncRun() {
    widget.input.runHeld = _runPointers.isNotEmpty && widget.input.enabled;
  }

  /// Saut maintenu tant qu'un doigt est sur le pad jump.
  void _syncJump() {
    widget.input.setTouchJump(_jumpPointers.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pad(
          pointers: _jumpPointers,
          sync: _syncJump,
          label: 'HOLD JUMP',
        ),
        _pad(
          pointers: _runPointers,
          sync: _syncRun,
          label: 'HOLD RUN',
        ),
      ],
    );
  }

  Widget _pad({
    required Set<int> pointers,
    required VoidCallback sync,
    required String label,
  }) {
    return Expanded(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          pointers.add(event.pointer);
          sync();
        },
        onPointerUp: (event) {
          pointers.remove(event.pointer);
          sync();
        },
        onPointerCancel: (event) {
          pointers.remove(event.pointer);
          sync();
        },
        child: _PadHint(
          label: label,
          align: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _PadHint extends StatelessWidget {
  const _PadHint({required this.label, required this.align});

  final String label;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(
          label,
          style: const TextStyle(
            color: Palette.hudMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
