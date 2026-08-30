import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/domain/medals.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/ui/sprite_sheet_animation.dart';

class WinOverlay extends StatefulWidget {
  WinOverlay({
    super.key,
    required this.time,
    required this.personalBest,
    required this.onRetry,
    required this.onMenu,
    this.onNext,
    String? menuLabel,
    this.showPersonalBest = true,
    this.previousBest,
    this.bronzeTime,
    this.silverTime,
    this.goldTime,
    this.authorTime,
  }) : menuLabel = menuLabel ?? AppString.menu;

  final double time;
  final double? personalBest;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback? onNext;
  final String menuLabel;
  final bool showPersonalBest;

  /// PB before this run. Already-owned medals use this; new ones animate.
  final double? previousBest;
  final double? bronzeTime;
  final double? silverTime;
  final double? goldTime;
  final double? authorTime;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  static const _slotSize = 48.0;

  late final AnimationController _reveal;

  bool get _isPersonalBest =>
      widget.showPersonalBest &&
      (widget.personalBest == null || widget.time <= widget.personalBest!);

  MedalReveal get _bronze => medalReveal(
    runTime: widget.time,
    previousBest: widget.previousBest,
    target: widget.bronzeTime,
  );

  MedalReveal get _silver => medalReveal(
    runTime: widget.time,
    previousBest: widget.previousBest,
    target: widget.silverTime,
  );

  MedalReveal get _gold => medalReveal(
    runTime: widget.time,
    previousBest: widget.previousBest,
    target: widget.goldTime,
  );

  bool get _authorOwned => medalEarned(widget.previousBest, widget.authorTime);

  bool get _authorJustEarned =>
      !_authorOwned && medalEarned(widget.time, widget.authorTime);

  bool get _authorUnlocked => _authorOwned || _authorJustEarned;

  bool get _hasJustEarned =>
      _bronze == MedalReveal.justEarned ||
      _silver == MedalReveal.justEarned ||
      _gold == MedalReveal.justEarned ||
      _authorJustEarned;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (_hasJustEarned) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

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
                  Text(
                    AppString.clear,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Palette.menuAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isPersonalBest) ...[
                    Text(
                      AppString.personalBest,
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
                    formatRunTime(widget.time),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (widget.showPersonalBest && !_isPersonalBest) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppString.personalBestShort(
                        formatRunTime(widget.personalBest!),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Palette.hudMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  if (widget.showPersonalBest) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MedalSlot(
                          asset: GameSprites.bundle(GameSprites.medalCopper),
                          reveal: _bronze,
                          animation: _reveal,
                          start: 0,
                          end: 0.45,
                          size: _slotSize,
                        ),
                        const SizedBox(width: 14),
                        _MedalSlot(
                          asset: GameSprites.bundle(GameSprites.medalSilver),
                          reveal: _silver,
                          animation: _reveal,
                          start: 0.18,
                          end: 0.63,
                          size: _slotSize,
                        ),
                        const SizedBox(width: 14),
                        _MedalSlot(
                          asset: GameSprites.bundle(GameSprites.medalGold),
                          reveal: _gold,
                          animation: _reveal,
                          start: 0.36,
                          end: 0.81,
                          size: _slotSize,
                        ),
                      ],
                    ),
                    if (_authorUnlocked) ...[
                      const SizedBox(height: 14),
                      _AuthorGem(
                        justEarned: _authorJustEarned,
                        animation: _reveal,
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _WinButton(
                          label: AppString.retry,
                          onTap: widget.onRetry,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (widget.onNext != null)
                        Expanded(
                          child: _WinButton(
                            label: AppString.next,
                            onTap: widget.onNext!,
                            accent: true,
                          ),
                        )
                      else
                        Expanded(
                          child: _WinButton(
                            label: widget.menuLabel,
                            onTap: widget.onMenu,
                          ),
                        ),
                    ],
                  ),
                  if (widget.onNext != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onMenu,
                      child: Text(widget.menuLabel),
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

class _MedalSlot extends StatelessWidget {
  const _MedalSlot({
    required this.asset,
    required this.reveal,
    required this.animation,
    required this.start,
    required this.end,
    required this.size,
  });

  final String asset;
  final MedalReveal reveal;
  final Animation<double> animation;
  final double start;
  final double end;
  final double size;

  @override
  Widget build(BuildContext context) {
    final empty = _EmptyMedal(size: size);
    if (reveal == MedalReveal.empty) {
      return empty;
    }
    final medal = SpriteSheetAnimation(asset: asset, size: size);
    return Stack(
      alignment: Alignment.center,
      children: [
        empty,
        if (reveal == MedalReveal.owned)
          medal
        else
          _PopIn(animation: animation, start: start, end: end, child: medal),
      ],
    );
  }
}

class _EmptyMedal extends StatelessWidget {
  const _EmptyMedal({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x33000000),
        border: Border.all(color: Palette.hudMuted.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _AuthorGem extends StatelessWidget {
  const _AuthorGem({
    required this.justEarned,
    required this.animation,
  });

  final bool justEarned;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final gem = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpriteSheetAnimation(
          asset: GameSprites.bundle(GameSprites.authorGem),
          size: 36,
          frameCount: 5,
        ),
        const SizedBox(width: 10),
        Stack(
          children: [
            Text(
              AppString.authorGem,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = Colors.black,
              ),
            ),
            Text(
              AppString.authorGem,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Palette.authorGem,
              ),
            ),
          ],
        ),
      ],
    );
    if (!justEarned) {
      return gem;
    }
    return _PopIn(
      animation: animation,
      start: 0.55,
      end: 1,
      child: gem,
    );
  }
}

class _PopIn extends StatelessWidget {
  const _PopIn({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final scale = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
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
