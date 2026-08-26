import 'package:odd/game/config.dart';

/// Intentions partagées : pads tactiles et clavier écrivent ici.
class GameInput {
  bool runHeld = false;
  bool enabled = true;

  bool _touchJump = false;
  bool _keyboardJump = false;
  double _jumpBuffer = 0;

  bool get jumpHeld => enabled && (_touchJump || _keyboardJump);

  /// Maintien du saut depuis l'écran tactile.
  void setTouchJump(bool held) {
    _touchJump = _holdJump(_touchJump, held);
  }

  /// Maintien du saut depuis le clavier.
  void setKeyboardJump(bool held) {
    _keyboardJump = _holdJump(_keyboardJump, held);
  }

  /// Relance le buffer si on vient d'appuyer (saut un peu en avance).
  bool _holdJump(bool wasHeld, bool held) {
    final next = held && enabled;
    if (next && !wasHeld) {
      _jumpBuffer = GameConfig.jumpBuffer;
    }
    return next;
  }

  /// Fait expirer le buffer de saut.
  void update(double dt) {
    if (_jumpBuffer > 0) {
      _jumpBuffer -= dt;
    }
  }

  bool get wantsJump => enabled && _jumpBuffer > 0;

  /// Consomme le saut (évite un double saut sur le même appui).
  void consumeJump() => _jumpBuffer = 0;

  /// Relâche run + saut (écran de victoire).
  void clearHolds() {
    runHeld = false;
    _touchJump = false;
    _keyboardJump = false;
    _jumpBuffer = 0;
  }

  /// Nouvelle run : input réactivé, rien n'est maintenu.
  void reset() {
    clearHolds();
    enabled = true;
  }
}
