import 'dart:ui';

import 'package:flame/components.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/domain/player_rules.dart';
import 'package:odd/game/collision/collision_grid.dart';
import 'package:odd/game/config.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/sprites.dart';
import 'package:odd/game/world/coin.dart';

/// Pingouin : physique, collisions, saut / wall-jump, pièces.
class Player extends PositionComponent with HasGameReference {
  Player({
    required this.grid,
    required this.input,
    required this.hud,
    required this.coins,
    required this.onDeath,
    required Vector2 spawn,
  }) : super(
         position: spawn,
         size: Vector2(GameConfig.playerWidth, GameConfig.playerHeight),
         anchor: Anchor.center,
         priority: 20,
       );

  final CollisionGrid grid;
  final GameInput input;
  final HudState hud;
  final List<Coin> coins;
  final VoidCallback onDeath;

  final Vector2 velocity = Vector2.zero();
  late final SpriteAnimationComponent _sprite;

  int _facing = 1;
  bool _grounded = false;
  bool _touchingLeft = false;
  bool _touchingRight = false;
  int _lastWall = 0;
  double _coyote = 0;
  double _wallCoyote = 0;
  bool _wasGrounded = false;

  /// Boîte de collision = taille du composant.
  Rect get hitbox {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x,
      height: size.y,
    );
  }

  /// Découpe 4 frames du pingouin dans la feuille 128×32.
  @override
  Future<void> onLoad() async {
    const art = 16.0;
    const insetX = 8.0;
    const insetY = 16.0;
    const slot = 32.0;
    final sheet = game.images.fromCache(GameSprites.player);
    // Une frame par slot de 32 px.
    final frames = [
      for (var i = 0; i < 4; i++)
        Sprite(
          sheet,
          srcPosition: Vector2(insetX + i * slot, insetY),
          srcSize: Vector2.all(art),
        ),
    ];
    _sprite = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(frames, stepTime: 0.12),
      size: size.clone(),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_sprite);
  }

  /// Bande sous les pieds pour détecter le sol.
  Rect get _feetProbe {
    return Rect.fromLTRB(
      hitbox.left + GameConfig.skin,
      hitbox.bottom,
      hitbox.right - GameConfig.skin,
      hitbox.bottom + 2,
    );
  }

  /// Un tick : gravité, saut, déplacement, pièces, squash, mort.
  @override
  void update(double dt) {
    super.update(dt);
    // Plus de contrôle une fois le niveau fini.
    if (hud.won) {
      return;
    }

    dt = dt.clamp(0, GameConfig.maxDt);

    velocity.y += GameConfig.gravity * dt;
    // Relâcher le saut en montée raccourcit l'arc (short hop).
    if (velocity.y < 0 && !input.jumpHeld) {
      velocity.y +=
          GameConfig.gravity * (GameConfig.jumpReleaseGravity - 1) * dt;
    }
    // Plafond de vitesse de chute.
    if (velocity.y > GameConfig.maxFallSpeed) {
      velocity.y = GameConfig.maxFallSpeed;
    }

    _separateFromSolids();
    _probeWalls();
    _updateCoyote(dt);
    _updateHorizontal(dt);
    _tryJump();

    _moveX(dt);
    hud.setHorizontalSpeed(velocity.x.abs());
    _moveY(dt);
    _probeWalls();
    _collectCoins();
    _syncSprite();

    // Tombé sous la carte → restart.
    if (position.y > grid.level.worldHeight + GameConfig.deathMargin) {
      onDeath();
      return;
    }

    // Atterrissage : squash horizontal.
    if (_grounded && !_wasGrounded) {
      scale.setValues(1.18, 0.82);
    }
    _wasGrounded = _grounded;

    // Retour progressif à l'échelle 1.
    scale
      ..x += (1 - scale.x) * dt * 14
      ..y += (1 - scale.y) * dt * 14;
  }

  /// Coyote au sol et coyote mural (saut un peu après avoir quitté).
  void _updateCoyote(double dt) {
    if (_grounded) {
      _coyote = GameConfig.coyoteTime;
    } else if (_coyote > 0) {
      _coyote -= dt;
    }

    if (_touchingLeft || _touchingRight) {
      _lastWall = _touchingLeft ? -1 : 1;
      _wallCoyote = GameConfig.wallCoyoteTime;
    } else if (_wallCoyote > 0) {
      _wallCoyote -= dt;
    }
  }

  /// Accel / décél au sol (sauf glace) ; en l'air, drift vers [airMaxSpeed].
  void _updateHorizontal(double dt) {
    if (_grounded) {
      final surface = grid.surfaceBelow(_feetProbe);
      // La glace ne freine ni n'accélère.
      if (surface != GroundSurface.ice) {
        final maxSpeed = surface == GroundSurface.mud
            ? GameConfig.mudSpeed
            : GameConfig.runSpeed;
        velocity.x = PlayerRules.approach(
          velocity.x,
          input.runHeld ? _facing * maxSpeed : 0,
          input.runHeld ? GameConfig.runAccel : GameConfig.runDecel,
          dt,
        );
      }
      return;
    }

    // Run : on se rapproche du plafond aérien. Relâché : on glisse vers 0.
    velocity.x = velocity.x
        .clamp(-GameConfig.airMaxSpeed, GameConfig.airMaxSpeed)
        .toDouble();
    velocity.x = PlayerRules.approach(
      velocity.x,
      input.runHeld ? _facing * GameConfig.airMaxSpeed : 0,
      input.runHeld ? GameConfig.airAccel : GameConfig.airDecel,
      dt,
    );
  }

  /// Saut au sol (ou coyote) prioritaire, sinon wall-jump.
  void _tryJump() {
    final canGroundJump = _grounded || _coyote > 0;
    final canWallJump =
        !canGroundJump && (_touchingLeft || _touchingRight || _wallCoyote > 0);
    if (!input.wantsJump) {
      return;
    }
    if (canGroundJump) {
      velocity.y = GameConfig.jumpSpeed;
      _grounded = false;
      _coyote = 0;
      input.consumeJump();
      scale.setValues(0.82, 1.22);
      return;
    }
    if (!canWallJump) {
      return;
    }
    _facing = PlayerRules.facingAfterWallJump(
      facing: _facing,
      touchingLeft: _touchingLeft,
      touchingRight: _touchingRight,
      lastWall: _lastWall,
    );
    velocity
      ..x = _facing * GameConfig.wallJumpX
      ..y = GameConfig.wallJumpSpeed;
    _wallCoyote = 0;
    position.x += _facing * 2;
    _separateFromSolids();
    input.consumeJump();
    scale.setValues(0.82, 1.22);
  }

  /// Recale X puis Y si on est déjà dans un bloc (spawn, wall-jump).
  void _separateFromSolids() {
    _resolveX();
    _resolveY();
    _clampX();
  }

  /// Avance en X puis éjecte des murs ; stoppe la vitesse si on a heurté.
  void _moveX(double dt) {
    position.x += velocity.x * dt;
    final attempted = position.x;
    _resolveX();
    if ((position.x - attempted).abs() > 0.001) {
      velocity.x = 0;
    }
    _clampX();
  }

  /// Avance en Y : atterrissage (solide au-dessus) ou plafond.
  void _moveY(double dt) {
    _grounded = false;
    position.y += velocity.y * dt;
    final attempted = position.y;
    _resolveY();
    // On a été poussé vers le haut → on est sur un sol.
    if (position.y < attempted - 0.001) {
      _grounded = true;
      if (velocity.y > 0) {
        velocity.y = 0;
      }
    } else if (position.y > attempted + 0.001) {
      // Poussé vers le bas → tête contre un plafond.
      if (velocity.y < 0) {
        velocity.y = 0;
      }
    }

    // Filet : pieds encore dans un solide.
    if (!_grounded) {
      _grounded = grid.overlapsSolid(_feetProbe);
      if (_grounded && velocity.y > 0) {
        velocity.y = 0;
      }
    }
  }

  /// Éjecte hors des blocs sur l'axe X.
  void _resolveX() {
    position.x = grid.separateX(
      centerX: position.x,
      centerY: position.y,
      halfWidth: size.x / 2,
      halfHeight: size.y / 2,
      skin: GameConfig.skin,
    );
  }

  /// Éjecte hors des blocs sur l'axe Y.
  void _resolveY() {
    position.y = grid.separateY(
      centerX: position.x,
      centerY: position.y,
      halfWidth: size.x / 2,
      halfHeight: size.y / 2,
      skin: GameConfig.skin,
    );
  }

  /// Empêche de sortir des bords gauche / droit de la carte.
  void _clampX() {
    final halfW = size.x / 2;
    position.x = position.x.clamp(halfW, grid.level.worldWidth - halfW);
  }

  /// Sondes à gauche et à droite pour le wall-jump.
  void _probeWalls() {
    final inset = GameConfig.skin + 2;
    _touchingLeft = grid.overlapsSolid(
      Rect.fromLTRB(
        hitbox.left - GameConfig.wallProbe,
        hitbox.top + inset,
        hitbox.left - 0.05,
        hitbox.bottom - inset,
      ),
    );
    _touchingRight = grid.overlapsSolid(
      Rect.fromLTRB(
        hitbox.right + 0.05,
        hitbox.top + inset,
        hitbox.right + GameConfig.wallProbe,
        hitbox.bottom - inset,
      ),
    );
  }

  /// Flip, course animée, ou pose / saut figé.
  void _syncSprite() {
    if (!isLoaded) {
      return;
    }
    _sprite.scale.x = _facing.toDouble();
    final running = _grounded && velocity.x.abs() > 12;
    _sprite.playing = running;
    if (!running) {
      _sprite.animationTicker?.currentIndex = _grounded ? 0 : 1;
    }
  }

  /// Ramasse les pièces dont la hitbox chevauche le joueur.
  void _collectCoins() {
    for (final coin in coins) {
      if (coin.collected) {
        continue;
      }
      if (hitbox.overlaps(coin.hitbox)) {
        coin.collect();
        hud.collectCoin();
      }
    }
  }
}
