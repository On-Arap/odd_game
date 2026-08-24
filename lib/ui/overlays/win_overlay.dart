import 'package:flutter/material.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';

class WinOverlay extends StatelessWidget {
  const WinOverlay({
    super.key,
    required this.time,
    required this.onRetry,
    required this.onMenu,
    this.onNext,
  });

  final double time;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Palette.menuCard,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CLEAR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Palette.menuAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRunTime(time),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _WinButton(label: 'RETRY', onTap: onRetry),
                      ),
                      const SizedBox(width: 10),
                      if (onNext != null)
                        Expanded(
                          child: _WinButton(
                            label: 'NEXT',
                            onTap: onNext!,
                            accent: true,
                          ),
                        )
                      else
                        Expanded(
                          child: _WinButton(label: 'MENU', onTap: onMenu),
                        ),
                    ],
                  ),
                  if (onNext != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onMenu,
                      child: const Text('MENU'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinButton extends StatelessWidget {
  const _WinButton({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: accent ? Palette.menuAccent : Colors.white12,
        foregroundColor: accent ? Colors.white : Palette.hud,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
