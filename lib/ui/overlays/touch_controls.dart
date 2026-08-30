import 'package:flutter/material.dart';
import 'package:odd/game/input/game_input.dart';

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
        _pad(pointers: _jumpPointers, sync: _syncJump),
        _pad(pointers: _runPointers, sync: _syncRun),
      ],
    );
  }

  Widget _pad({
    required Set<int> pointers,
    required VoidCallback sync,
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
        child: const SizedBox.expand(),
      ),
    );
  }
}
