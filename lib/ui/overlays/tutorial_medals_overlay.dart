import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/ui/sprite_sheet_animation.dart';

/// Modal objectifs : 3 médailles + gem animées, puis le texte de fin de tuto.
class TutorialMedalsOverlay extends StatelessWidget {
  const TutorialMedalsOverlay({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: Palette.menuCard,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpriteSheetAnimation(
                        asset: GameSprites.bundle(GameSprites.medalCopper),
                        size: 48,
                      ),
                      SizedBox(width: 12),
                      SpriteSheetAnimation(
                        asset: GameSprites.bundle(GameSprites.medalSilver),
                        size: 48,
                      ),
                      SizedBox(width: 12),
                      SpriteSheetAnimation(
                        asset: GameSprites.bundle(GameSprites.medalGold),
                        size: 48,
                      ),
                      SizedBox(width: 12),
                      SpriteSheetAnimation(
                        asset: GameSprites.bundle(GameSprites.authorGem),
                        size: 48,
                        frameCount: 5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppString.medalsTutorialBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.menuAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        AppString.ok,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
