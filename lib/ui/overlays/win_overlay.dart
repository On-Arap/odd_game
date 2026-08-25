import 'package:flutter/material.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';

class WinOverlay extends StatelessWidget {
  const WinOverlay({
    super.key,
    required this.time,
    required this.personalBest,
    required this.onRetry,
    required this.onMenu,
    this.onNext,
    this.menuLabel = 'MENU',
    this.showPersonalBest = true,
    this.authorTime,
  });

  final double time;
  final double? personalBest;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback? onNext;
  final String menuLabel;
  final bool showPersonalBest;
  final double? authorTime;

  bool get _isPersonalBest =>
      showPersonalBest && (personalBest == null || time <= personalBest!);

  bool get _beatAuthor =>
      authorTime != null && time <= authorTime!;

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
                  if (_isPersonalBest) ...[
                    const Text(
                      'PERSONAL BEST :',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Palette.menuAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    formatRunTime(time),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (showPersonalBest && !_isPersonalBest) ...[
                    const SizedBox(height: 6),
                    Text(
                      'PB ${formatRunTime(personalBest!)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Palette.hudMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  if (showPersonalBest && authorTime != null) ...[
                    const SizedBox(height: 16),
                    _AuthorTimeMedal(
                      beaten: _beatAuthor,
                      authorTime: authorTime!,
                    ),
                  ],
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
                          child: _WinButton(label: menuLabel, onTap: onMenu),
                        ),
                    ],
                  ),
                  if (onNext != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onMenu,
                      child: Text(menuLabel),
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

class _AuthorTimeMedal extends StatelessWidget {
  const _AuthorTimeMedal({
    required this.beaten,
    required this.authorTime,
  });

  final bool beaten;
  final double authorTime;

  @override
  Widget build(BuildContext context) {
    final color = beaten ? Palette.coin : Palette.hudMuted;
    return Column(
      children: [
        Icon(
          Icons.emoji_events,
          color: color,
          size: 42,
        ),
        const SizedBox(height: 4),
        Text(
          beaten ? 'Author Time beaten' : 'Author Time ${formatRunTime(authorTime)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
