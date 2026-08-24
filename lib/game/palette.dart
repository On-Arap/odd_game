import 'dart:ui';

import 'package:odd/domain/level_map.dart';

abstract final class Palette {
  static const background = Color(0xFF1F1F1F);
  static const snowFill = Color(0xFF383455);
  static const groundA = Color(0xFF4D4D4D);
  static const groundB = Color(0xFF626262);
  static const iceA = Color(0xFF7EC8E3);
  static const iceB = Color(0xFFB8E4F5);
  static const mudA = Color(0xFF6B4423);
  static const mudB = Color(0xFF8A5A32);
  static const player = Color(0xFF2A7F78);
  static const playerEye = Color(0xFFFFF4E6);
  static const coin = Color(0xFFFFC53D);
  static const coinInner = Color(0xFFFFE89A);
  static const hud = Color(0xFFE8ECF1);
  static const hudMuted = Color(0x99E8ECF1);
  static const menuCard = Color(0xFFACACAC);
  static const menuAccent = Color(0xFF13534E);

  static Color tile(String cell, int col, int row) {
    final even = (col + row).isEven;
    switch (cell) {
      case TileCodes.ice:
        return even ? iceA : iceB;
      case TileCodes.mud:
        return even ? mudA : mudB;
      default:
        return even ? groundA : groundB;
    }
  }
}
