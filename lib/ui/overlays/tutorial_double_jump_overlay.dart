import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/game/palette.dart';
import 'package:video_player/video_player.dart';

/// Modal double jump : jeu en pause, vidéo muette + explication.
class TutorialDoubleJumpOverlay extends StatefulWidget {
  const TutorialDoubleJumpOverlay({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const asset = 'assets/tutorial/double_jump.mp4';

  @override
  State<TutorialDoubleJumpOverlay> createState() =>
      _TutorialDoubleJumpOverlayState();
}

class _TutorialDoubleJumpOverlayState extends State<TutorialDoubleJumpOverlay> {
  late final VideoPlayerController _player;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.asset(TutorialDoubleJumpOverlay.asset)
      ..setVolume(0)
      ..setLooping(true);
    _player.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _player.play();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _player.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _player.value.aspectRatio == 0
                                ? 16 / 9
                                : _player.value.aspectRatio,
                            child: VideoPlayer(_player),
                          )
                        : const SizedBox(
                            height: 160,
                            child: ColoredBox(color: Color(0x33000000)),
                          ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppString.doubleJumpTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Palette.menuAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppString.doubleJumpBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.menuAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        AppString.ok,
                        style: TextStyle(fontWeight: FontWeight.w800),
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
