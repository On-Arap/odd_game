import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/ui/overlays/tutorial_modal_card.dart';
import 'package:video_player/video_player.dart';

/// Modal walljump : jeu en pause, vidéo muette + explication.
class TutorialWalljumpOverlay extends StatelessWidget {
  const TutorialWalljumpOverlay({
    super.key,
    required this.onContinue,
    required this.player,
  });

  final VoidCallback onContinue;
  final VideoPlayerController player;

  static const asset = 'assets/tutorial/walljump.mp4';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: TutorialModalCard(
        media: TutorialVideoView(player: player),
        title: AppString.walljumpTitle,
        body: AppString.walljumpBody,
        onContinue: onContinue,
      ),
    );
  }
}
