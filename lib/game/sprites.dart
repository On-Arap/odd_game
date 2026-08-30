import 'package:odd/domain/level_map.dart';

/// Chemins d'images (relatifs à [bundlePrefix]) pour Flame et l'éditeur.
abstract final class GameSprites {
  static const bundlePrefix = 'assets/sprites/';

  static const player = 'player/penguin.png';
  static const coin = 'objects/coin_gold.png';
  static const medalGold = 'objects/medal_gold.png';
  static const medalSilver = 'objects/medal_silver.png';
  static const medalCopper = 'objects/medal_copper.png';
  static const authorGem = 'objects/author_gem.png';
  static const bloc = 'tilesets/bloc.png';
  static const ice = 'tilesets/ice.png';
  static const mud = 'tilesets/mud.png';

  static const all = [player, coin, bloc, ice, mud];

  /// Préfixe Flutter `assets/…` (l'éditeur ne passe pas par Flame).
  static String bundle(String relative) => '$bundlePrefix$relative';

  /// Sprite de sol pour `#` / `I` / `M`, sinon null (air, P, C).
  static String? tile(String cell) => switch (cell) {
    TileCodes.ice => ice,
    TileCodes.mud => mud,
    TileCodes.solid => bloc,
    _ => null,
  };
}
