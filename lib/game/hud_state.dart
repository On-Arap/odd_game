import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// État HUD partagé (pièces, chrono, victoire) notifié à Flutter.
class HudState extends ChangeNotifier {
  int coinsCollected = 0;
  int coinsTotal = 0;
  double elapsed = 0;
  bool won = false;
  double horizontalSpeed = 0;
  bool timerRunning = false;
  double _hudEmit = 0;
  bool _notifyScheduled = false;

  /// Reset pour une nouvelle tentative.
  void begin({required int coins}) {
    coinsCollected = 0;
    coinsTotal = coins;
    elapsed = 0;
    won = false;
    horizontalSpeed = 0;
    timerRunning = false;
    _hudEmit = 0;
    _notify();
  }

  /// Avance le chrono (rafraîchit l'UI ~20 fois/s).
  void tick(double dt) {
    if (won || !timerRunning) {
      return;
    }
    elapsed += dt;
    _hudEmit += dt;
    if (_hudEmit >= 0.05) {
      _hudEmit = 0;
      _notify();
    }
  }

  /// Démarre le chrono au premier input.
  void startTimer() {
    if (timerRunning || won) {
      return;
    }
    timerRunning = true;
  }

  /// +1 pièce ; victoire si le compte est plein.
  void collectCoin() {
    if (won) {
      return;
    }
    coinsCollected++;
    if (coinsCollected >= coinsTotal) {
      won = true;
    }
    _notify();
  }

  /// Ignore les micro-variations de vitesse (HUD).
  void setHorizontalSpeed(double speed) {
    if ((speed - horizontalSpeed).abs() < 0.5) {
      return;
    }
    horizontalSpeed = speed;
    _notify();
  }

  /// Flame update pendant le layout Flutter : notify en post-frame si besoin.
  void _notify() {
    if (_notifyScheduled) {
      return;
    }
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }
}

/// Affiche `s.xx` ou `m:ss.xx`.
String formatRunTime(double seconds) {
  final whole = seconds.floor();
  final minutes = whole ~/ 60;
  final secs = whole % 60;
  final hundredths = ((seconds - whole) * 100).floor().clamp(0, 99);
  final frac = hundredths.toString().padLeft(2, '0');
  if (minutes > 0) {
    return '$minutes:${secs.toString().padLeft(2, '0')}.$frac';
  }
  return '$secs.$frac';
}
