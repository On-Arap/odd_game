import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/collision/collision_grid.dart';
import 'package:odd/game/config.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/input/keyboard_bridge.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/player/player.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/game/world/coin.dart';

/// Moteur Flame : charge les sprites, construit le niveau, avance la simu.
class OddGame extends FlameGame with HasKeyboardHandlerComponents {
  OddGame({required this.level, required this.input, required this.hud})
    : super(
        camera: CameraComponent.withFixedResolution(
          width: GameConfig.viewWidth,
          height: GameConfig.viewHeight,
        ),
      );

  final LevelMap level;
  final GameInput input;
  final HudState hud;

  final List<Coin> coins = [];
  bool _restartQueued = false;

  /// Fond uni derrière le monde.
  @override
  Color backgroundColor() => Palette.background;

  /// Charge les images, branche le clavier, puis pose le niveau.
  @override
  Future<void> onLoad() async {
    images.prefix = GameSprites.bundlePrefix;
    // Précharge pingouin, pièces et tuiles (bloc / glace / boue).
    await images.loadAll(GameSprites.all);
    camera.viewfinder.anchor = Anchor.center;
    add(KeyboardBridge(input, onRestart: queueRestart));
    spawnLevel();
  }

  /// Demande un reset au prochain tick (évite de recréer le monde en plein update).
  void queueRestart() {
    _restartQueued = true;
  }

  /// Vide le monde et replace tuiles, pièces, joueur et caméra.
  void spawnLevel() {
    camera.stop();
    world.removeAll(world.children.toList());
    coins.clear();
    input.reset();
    hud.begin(coins: level.coinCount);
    final grid = CollisionGrid(level);

    final tile = level.tileSize;
    // Parcourt la grille : une SpriteComponent par cellule solide.
    for (var row = 0; row < level.rows; row++) {
      for (var col = 0; col < level.cols; col++) {
        final path = GameSprites.tile(level.tileAt(col, row));
        // Air, spawn et pièces n'ont pas de sprite de sol.
        if (path == null) {
          continue;
        }
        world.add(
          SpriteComponent(
            position: Vector2(col * tile, row * tile),
            size: Vector2(tile, tile),
            sprite: Sprite(images.fromCache(path)),
          ),
        );
      }
    }

    // Place chaque pièce au centre de sa case.
    for (final pos in level.coins) {
      final coin = Coin(
        center: Vector2((pos.col + 0.5) * tile, (pos.row + 0.5) * tile),
      );
      coins.add(coin);
      world.add(coin);
    }

    // Spawn : pieds sur le bas de la case P.
    final spawn = Vector2(
      (level.spawn.col + 0.5) * tile,
      (level.spawn.row + 1) * tile - GameConfig.playerHeight / 2,
    );
    final hero = Player(
      grid: grid,
      input: input,
      hud: hud,
      coins: coins,
      onDeath: queueRestart,
      spawn: spawn,
    );
    world.add(hero);
    camera.follow(hero, snap: true);
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, level.worldWidth, level.worldHeight),
      considerViewport: true,
    );
    paused = false;
    _restartQueued = false;
  }

  /// Restart, chrono, physique, puis bloque l'input une fois gagné.
  @override
  void update(double dt) {
    // Recrée le niveau si le joueur est mort ou a relancé.
    if (_restartQueued) {
      spawnLevel();
    }
    // Le chrono part au premier run / saut.
    if (input.runHeld || input.jumpHeld || input.wantsJump) {
      hud.startTimer();
    }
    super.update(dt);
    input.update(dt);
    hud.tick(dt);
    // Plus d'input après la dernière pièce.
    if (hud.won) {
      input.enabled = false;
      input.clearHolds();
    }
  }
}
