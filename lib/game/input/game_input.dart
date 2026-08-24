import 'package:odd/game/config.dart';

/// Shared intent bus. Flutter touch pads and the keyboard both write here.
class GameInput {
  bool runHeld = false;
  bool enabled = true;

  bool _touchJump = false;
  bool _keyboardJump = false;
  double _jumpBuffer = 0;

  bool get jumpHeld => enabled && (_touchJump || _keyboardJump);

  void setTouchJump(bool held) {
    _touchJump = _holdJump(_touchJump, held);
  }

  void setKeyboardJump(bool held) {
    _keyboardJump = _holdJump(_keyboardJump, held);
  }

  bool _holdJump(bool wasHeld, bool held) {
    final next = held && enabled;
    if (next && !wasHeld) {
      _jumpBuffer = GameConfig.jumpBuffer;
    }
    return next;
  }

  void update(double dt) {
    if (_jumpBuffer > 0) {
      _jumpBuffer -= dt;
    }
  }

  bool get wantsJump => enabled && _jumpBuffer > 0;

  void consumeJump() => _jumpBuffer = 0;

  void clearHolds() {
    runHeld = false;
    _touchJump = false;
    _keyboardJump = false;
    _jumpBuffer = 0;
  }

  void reset() {
    clearHolds();
    enabled = true;
  }
}
