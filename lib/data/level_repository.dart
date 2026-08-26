import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:odd/domain/level_map.dart';

class LevelRepository {
  static const indexAsset = 'assets/maps/index.json';

  /// Charge l'index puis chaque fichier de map listé.
  Future<List<LevelMap>> loadAll() async {
    final raw =
        jsonDecode(await rootBundle.loadString(indexAsset)) as Map<String, dynamic>;
    final files = (raw['levels'] as List).cast<String>();
    final levels = <LevelMap>[];
    for (final file in files) {
      levels.add(await load(file));
    }
    return levels;
  }

  /// Parse un JSON de map depuis les assets.
  Future<LevelMap> load(String file) async {
    final source = await rootBundle.loadString('assets/maps/$file');
    return LevelMap.parseJson(source, file: file);
  }
}
