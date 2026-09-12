import 'package:flutter/material.dart';
import 'package:odd/game/palette.dart';

/// Carte centrée comme l'overlay victoire / tuto.
class GameDialogCard extends StatelessWidget {
  const GameDialogCard({
    super.key,
    required this.child,
    this.maxWidth = 380,
    this.maxHeight,
  });

  final Widget child;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxCardHeight =
        (maxHeight ?? MediaQuery.sizeOf(context).height - 24) - keyboard;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxCardHeight.clamp(120.0, 4000.0),
              ),
              child: Material(
                color: Palette.menuCard,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameDialogTitle extends StatelessWidget {
  const GameDialogTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        color: Palette.menuAccent,
      ),
    );
  }
}

class GameDialogButton extends StatelessWidget {
  const GameDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: Palette.menuAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Palette.menuAccent.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
    );
  }
}
