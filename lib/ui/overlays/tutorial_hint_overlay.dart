import 'package:flutter/material.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/palette.dart';

/// Masque une moitié d'écran et fait briller l'autre (tutoriel).
class TutorialHintOverlay extends StatefulWidget {
  const TutorialHintOverlay({
    super.key,
    required this.input,
    required this.onDismissed,
    required this.glowLeft,
    required this.title,
    required this.shouldDismiss,
    this.subtitle,
  });

  final GameInput input;
  final VoidCallback onDismissed;
  final bool glowLeft;
  final String title;
  final String? subtitle;
  final bool Function(GameInput input) shouldDismiss;

  @override
  State<TutorialHintOverlay> createState() => _TutorialHintOverlayState();
}

class _TutorialHintOverlayState extends State<TutorialHintOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _fade;
  var _dismissing = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulse.addListener(_watchInput);
    _fade.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed();
      }
    });
  }

  void _watchInput() {
    if (_dismissing || !widget.shouldDismiss(widget.input)) {
      return;
    }
    _dismissing = true;
    _fade.forward();
  }

  @override
  void dispose() {
    _pulse
      ..removeListener(_watchInput)
      ..dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = _GlowHalf(
      pulse: _pulse,
      title: widget.title,
      subtitle: widget.subtitle,
    );
    const mask = ColoredBox(
      color: Color(0xB3000000),
      child: SizedBox.expand(),
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_fade),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: widget.glowLeft ? glow : mask),
          Expanded(child: widget.glowLeft ? mask : glow),
        ],
      ),
    );
  }
}

class _GlowHalf extends StatelessWidget {
  const _GlowHalf({
    required this.pulse,
    required this.title,
    this.subtitle,
  });

  final Animation<double> pulse;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(pulse.value);
          return ColoredBox(
            color: Palette.menuAccent.withValues(alpha: 0.10 + 0.16 * t),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Palette.hud.withValues(alpha: 0.35 + 0.55 * t),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Palette.menuAccent.withValues(
                      alpha: 0.45 + 0.40 * t,
                    ),
                    blurRadius: 28 + 24 * t,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: SizedBox.expand(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.hud,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            shadows: _glowShadows(t),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Palette.hud,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              shadows: _glowShadows(t),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static List<Shadow> _glowShadows(double t) {
    return [
      Shadow(
        color: Palette.hud.withValues(alpha: 0.55 + 0.45 * t),
        blurRadius: 12 + 20 * t,
      ),
      Shadow(
        color: Palette.menuAccent.withValues(alpha: 0.50 + 0.50 * t),
        blurRadius: 28 + 36 * t,
      ),
      Shadow(
        color: Palette.menuAccent.withValues(alpha: 0.35 + 0.40 * t),
        blurRadius: 48 + 40 * t,
      ),
    ];
  }
}
