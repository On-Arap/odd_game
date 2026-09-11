import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/ui/overlays/tutorial_modal_card.dart';
import 'package:odd/ui/sprite_sheet_animation.dart';

/// Modal objectifs : 3 médailles + gem animées, puis le texte de fin de tuto.
class TutorialMedalsOverlay extends StatelessWidget {
  const TutorialMedalsOverlay({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: TutorialModalCard(
        media: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
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
        ),
        body: AppString.medalsTutorialBody,
        onContinue: onContinue,
      ),
    );
  }
}
