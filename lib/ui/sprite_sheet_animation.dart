import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Feuille horizontale animée comme la pièce en jeu (8 frames 16×16, 0.08 s).
class SpriteSheetAnimation extends StatefulWidget {
  const SpriteSheetAnimation({
    super.key,
    required this.asset,
    required this.size,
    this.frameCount = 8,
    this.frameSize = 16,
    this.stepTime = 0.08,
  });

  final String asset;
  final double size;
  final int frameCount;
  final int frameSize;
  final double stepTime;

  @override
  State<SpriteSheetAnimation> createState() => _SpriteSheetAnimationState();
}

class _SpriteSheetAnimationState extends State<SpriteSheetAnimation>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  late final Ticker _ticker;
  double _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = elapsed.inMicroseconds / 1e6);
    })..start();
    _load();
  }

  Future<void> _load() async {
    final data = await rootBundle.load(widget.asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _image = frame.image);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    final frame = (_elapsed / widget.stepTime).floor() % widget.frameCount;
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _SheetPainter(
        image: image,
        frame: frame,
        frameSize: widget.frameSize,
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  _SheetPainter({
    required this.image,
    required this.frame,
    required this.frameSize,
  });

  final ui.Image image;
  final int frame;
  final int frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      frame * frameSize.toDouble(),
      0,
      frameSize.toDouble(),
      frameSize.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_SheetPainter old) =>
      old.image != image || old.frame != frame || old.frameSize != frameSize;
}
