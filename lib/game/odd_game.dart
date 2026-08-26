import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/game/collision/collision_grid.dart';
import 'package:odd/game/config.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/input/keyboard_bridge.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/player/player.dart';
import 'package:odd/game/world/coin.dart';
import 'package:odd/game/world/ground_block.dart';

class OddGame extends FlameGame with HasKeyboardHandlerComponents {
  OddGame({
    required this.level,
    required this.input,
    required this.hud,
  }) : super(
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

  @override
  Color backgroundColor() => Palette.background;

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/sprites/';
    await images.loadAll([
      'player/penguin.png',
      'objects/coin_gold.png',
      'tilesets/bloc.png',
      'tilesets/ice.png',
    ]);
    camera.viewfinder.anchor = Anchor.center;
    add(KeyboardBridge(input, onRestart: queueRestart));
    spawnLevel();
  }

  void queueRestart() {
    _restartQueued = true;
  }

  void spawnLevel() {
    camera.stop();
    world.removeAll(world.children.toList());
    coins.clear();
    input.reset();
    hud.begin(coins: level.coinCount);
    final grid = CollisionGrid(level);

    final tile = level.tileSize;
    final bloc = images.fromCache('tilesets/bloc.png');
    final ice = images.fromCache('tilesets/ice.png');
    for (var row = 0; row < level.rows; row++) {
      for (var col = 0; col < level.cols; col++) {
        final cell = level.tileAt(col, row);
        if (!TileCodes.isSolid(cell)) {
          continue;
        }
        final at = Vector2(col * tile, row * tile);
        final size = Vector2(tile, tile);
        if (cell == TileCodes.ice) {
          world.add(
            GroundBlock.sprite(
              position: at,
              size: size,
              sprite: Sprite(ice),
            ),
          );
          continue;
        }
        if (cell == TileCodes.mud) {
          world.add(
            GroundBlock.color(
              position: at,
              size: size,
              color: Palette.tile(cell, col, row),
            ),
          );
          continue;
        }
        world.add(
          GroundBlock.sprite(
            position: at,
            size: size,
            sprite: Sprite(bloc),
          ),
        );
      }
    }

    for (final pos in level.coins) {
      final coin = Coin(
        center: Vector2((pos.col + 0.5) * tile, (pos.row + 0.5) * tile),
      );
      coins.add(coin);
      world.add(coin);
    }

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

  @override
  void update(double dt) {
    if (_restartQueued) {
      spawnLevel();
    }
    if (input.runHeld || input.jumpHeld || input.wantsJump) {
      hud.startTimer();
    }
    super.update(dt);
    input.update(dt);
    hud.tick(dt);
    if (hud.won) {
      input.enabled = false;
      input.clearHolds();
    }
  }
}
