import 'dart:async';

import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/game/palette.dart';
import 'package:video_player/video_player.dart';

/// Carte tutoriel bornée à l'écran : média flexible, texte qui se réduit, bouton
/// toujours visible.
class TutorialModalCard extends StatelessWidget {
  const TutorialModalCard({
    super.key,
    required this.body,
    required this.onContinue,
    this.media,
    this.title,
  });

  final Widget? media;
  final String? title;
  final String body;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const buttonBlock = 56.0;
            const titleBlock = 36.0;
            const cardPadding = 28.0;
            const spacing = 32.0;
            final reserved =
                buttonBlock +
                cardPadding +
                spacing +
                (title != null ? titleBlock : 0);
            final leftover = (constraints.maxHeight - reserved).clamp(
              48.0,
              constraints.maxHeight,
            );
            final mediaMax = media == null ? 0.0 : leftover * 0.65;
            final bodyMax = leftover - mediaMax;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Material(
                  color: Palette.menuCard,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (media != null) ...[
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: mediaMax),
                            child: media,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (title != null) ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              title!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Palette.menuAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: bodyMax,
                            minHeight: 0,
                          ),
                          child: LayoutBuilder(
                            builder: (context, bodyBox) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: bodyBox.maxWidth,
                                  child: Text(
                                    body,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: Palette.menuAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              AppString.ok,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Vidéo préchargée : lecture à l'affichage, pause à la fermeture.
class TutorialVideoView extends StatefulWidget {
  const TutorialVideoView({super.key, required this.player});

  final VideoPlayerController player;

  @override
  State<TutorialVideoView> createState() => _TutorialVideoViewState();
}

class _TutorialVideoViewState extends State<TutorialVideoView> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    widget.player.addListener(_onPlayer);
    _tryPlay();
  }

  @override
  void didUpdateWidget(covariant TutorialVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      oldWidget.player.removeListener(_onPlayer);
      _started = false;
      widget.player.addListener(_onPlayer);
      _tryPlay();
    }
  }

  @override
  void dispose() {
    widget.player.removeListener(_onPlayer);
    widget.player.pause();
    unawaited(widget.player.seekTo(Duration.zero));
    super.dispose();
  }

  void _onPlayer() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _tryPlay();
  }

  void _tryPlay() {
    if (_started || !widget.player.value.isInitialized) {
      return;
    }
    _started = true;
    widget.player
      ..setVolume(0)
      ..setLooping(true)
      ..play();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.player.value.isInitialized) {
      return const ColoredBox(
        color: Color(0x33000000),
        child: SizedBox(width: double.infinity, height: 80),
      );
    }
    final ratio = widget.player.value.aspectRatio == 0
        ? 16 / 9
        : widget.player.value.aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = width / ratio;
        if (constraints.maxHeight.isFinite && height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * ratio;
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayer(widget.player),
          ),
        );
      },
    );
  }
}
