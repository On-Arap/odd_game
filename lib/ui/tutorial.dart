import 'dart:async';

import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/tutorial_store.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/ui/overlays/tutorial_double_jump_overlay.dart';
import 'package:odd/ui/overlays/tutorial_hint_overlay.dart';
import 'package:odd/ui/overlays/tutorial_medals_overlay.dart';
import 'package:odd/ui/overlays/tutorial_walljump_overlay.dart';

/// Étapes persistées et overlays du tutoriel en jeu.
class Tutorial extends ChangeNotifier {
  Tutorial({TutorialStore? store}) : _store = store ?? TutorialStore();

  final TutorialStore _store;

  GameInput? _input;
  VoidCallback? _pause;
  VoidCallback? _resume;
  var _playtest = false;
  var _levelIndex = 0;
  var _showRunTutorial = false;
  var _disposed = false;

  int? level;
  var showJumpHint = false;
  var showDoubleJumpModal = false;
  var showWalljumpModal = false;
  var showMedalsModal = false;
  var coinsSeen = 0;

  static bool locksMaps(int tutorialLvl) => tutorialLvl == 0;

  bool get showRunHint {
    if (_playtest || _levelIndex != 0) {
      return false;
    }
    if (level != null) {
      return level == 0;
    }
    return _showRunTutorial;
  }

  bool get hasPausedModal =>
      showDoubleJumpModal || showWalljumpModal || showMedalsModal;

  /// Branche input / pause et reset les overlays pour un nouveau run.
  void startLevel({
    required GameInput input,
    required VoidCallback pause,
    required VoidCallback resume,
    required bool playtest,
    required int levelIndex,
    required bool showRunTutorial,
  }) {
    _input = input;
    _pause = pause;
    _resume = resume;
    _playtest = playtest;
    _levelIndex = levelIndex;
    _showRunTutorial = showRunTutorial;
    showJumpHint = false;
    showDoubleJumpModal = false;
    showWalljumpModal = false;
    showMedalsModal = false;
    coinsSeen = 0;
    input.allowJump = !showRunHint;
  }

  Future<void> load() async {
    if (_playtest) {
      return;
    }
    final stored = await _store.load();
    if (_disposed) {
      return;
    }
    if (level != null && level! > stored) {
      return;
    }
    level = stored;
    _input?.allowJump = !showRunHint;
    notifyListeners();
  }

  void syncOnCoin({required int coinsCollected, required bool won}) {
    if (_playtest) {
      return;
    }
    if (coinsCollected == 0) {
      coinsSeen = 0;
      if (showJumpHint || hasPausedModal) {
        if (hasPausedModal) {
          _resume?.call();
        }
        showJumpHint = false;
        showDoubleJumpModal = false;
        showWalljumpModal = false;
        showMedalsModal = false;
        notifyListeners();
      }
      return;
    }
    final pickedUp = coinsCollected > coinsSeen;
    coinsSeen = coinsCollected;
    if (!pickedUp || won) {
      return;
    }
    if (level == 1 && !showJumpHint) {
      showJumpHint = true;
      notifyListeners();
      return;
    }
    if (level == 2 && !showWalljumpModal) {
      _pause?.call();
      showWalljumpModal = true;
      notifyListeners();
      return;
    }
    if (level == 3 && !showDoubleJumpModal) {
      _pause?.call();
      showDoubleJumpModal = true;
      notifyListeners();
      return;
    }
    if (level == 4 && !showMedalsModal) {
      _pause?.call();
      showMedalsModal = true;
      notifyListeners();
    }
  }

  void dismissPausedModals() {
    if (!hasPausedModal) {
      return;
    }
    _resume?.call();
    showDoubleJumpModal = false;
    showWalljumpModal = false;
    showMedalsModal = false;
    notifyListeners();
  }

  Future<void> completeRun() async {
    await _store.save(1);
    if (_disposed) {
      return;
    }
    level = 1;
    _input?.allowJump = true;
    notifyListeners();
  }

  Future<void> completeJump() async {
    await _store.save(2);
    if (_disposed) {
      return;
    }
    level = 2;
    showJumpHint = false;
    notifyListeners();
  }

  Future<void> completeWalljump() async {
    await _store.save(3);
    if (_disposed) {
      return;
    }
    _resume?.call();
    level = 3;
    showWalljumpModal = false;
    notifyListeners();
  }

  Future<void> completeDoubleJump() async {
    await _store.save(4);
    if (_disposed) {
      return;
    }
    _resume?.call();
    level = 4;
    showDoubleJumpModal = false;
    notifyListeners();
  }

  Future<void> completeMedals() async {
    await _store.save(5);
    if (_disposed) {
      return;
    }
    _resume?.call();
    level = 5;
    showMedalsModal = false;
    notifyListeners();
  }

  List<Widget> hintOverlays(GameInput input) {
    return [
      if (showRunHint)
        Positioned.fill(
          child: TutorialHintOverlay(
            input: input,
            glowLeft: false,
            title: AppString.holdToRun,
            shouldDismiss: (input) => input.runHeld,
            onDismissed: () => unawaited(completeRun()),
          ),
        ),
      if (showJumpHint)
        Positioned.fill(
          child: TutorialHintOverlay(
            input: input,
            glowLeft: true,
            title: AppString.pressToJump,
            subtitle: AppString.jumpHoldHint,
            shouldDismiss: (input) => input.jumpHeld || input.wantsJump,
            onDismissed: () => unawaited(completeJump()),
          ),
        ),
    ];
  }

  List<Widget> modalOverlays() {
    return [
      if (showDoubleJumpModal)
        TutorialDoubleJumpOverlay(
          onContinue: () => unawaited(completeDoubleJump()),
        ),
      if (showWalljumpModal)
        TutorialWalljumpOverlay(
          onContinue: () => unawaited(completeWalljump()),
        ),
      if (showMedalsModal)
        TutorialMedalsOverlay(onContinue: () => unawaited(completeMedals())),
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
