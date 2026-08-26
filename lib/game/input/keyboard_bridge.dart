import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:odd/game/input/game_input.dart';

/// Traduit les touches en [GameInput] (run, saut, restart).
class KeyboardBridge extends Component with KeyboardHandler {
  KeyboardBridge(this.input, {this.onRestart});

  final GameInput input;
  final void Function()? onRestart;

  static final _runKeys = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  };

  static final _jumpKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.keyK,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.arrowUp,
  };

  /// Met à jour run/saut selon les touches encore enfoncées.
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    input.runHeld =
        input.enabled && keysPressed.intersection(_runKeys).isNotEmpty;
    input.setKeyboardJump(keysPressed.intersection(_jumpKeys).isNotEmpty);

    // R relance le niveau.
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
      onRestart?.call();
    }
    return true;
  }
}
