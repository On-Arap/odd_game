import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';

class HudOverlay extends StatelessWidget {
  HudOverlay({
    super.key,
    required this.hud,
    required this.onBack,
    required this.onRestart,
    String? backLabel,
  }) : backLabel = backLabel ?? AppString.menu;

  final HudState hud;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hud,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HudButton(label: backLabel, onTap: onBack),
                      const SizedBox(width: 8),
                      _HudButton(label: AppString.retry, onTap: onRestart),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRunTime(hud.elapsed),
                        style: const TextStyle(
                          color: Palette.hud,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        hud.horizontalSpeed.round().toString(),
                        style: const TextStyle(
                          color: Palette.hudMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    '${hud.coinsCollected}/${hud.coinsTotal}',
                    style: const TextStyle(
                      color: Palette.coin,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Palette.hud,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
