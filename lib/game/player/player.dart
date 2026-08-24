import 'dart:ui';

import 'package:flame/components.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/domain/player_rules.dart';
import 'package:odd/game/collision/collision_grid.dart';
import 'package:odd/game/config.dart';
import 'package:odd/game/hud_state.dart';
import 'package:odd/game/input/game_input.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/game/world/coin.dart';

class Player extends PositionComponent {
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
  final Paint _body = Paint()..color = Palette.player;
  final Paint _eye = Paint()..color = Palette.playerEye;

  int _facing = 1;
  bool _grounded = false;
  bool _touchingLeft = false;
  bool _touchingRight = false;
  int _lastWall = 0;
  double _coyote = 0;
  double _wallCoyote = 0;
  bool _wasGrounded = false;
  double _airTime = 0;
  double _takeoffSpeed = 0;

  Rect get hitbox {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x,
      height: size.y,
    );
  }

  Rect get _feetProbe {
    return Rect.fromLTRB(
      hitbox.left + GameConfig.skin,
      hitbox.bottom,
      hitbox.right - GameConfig.skin,
      hitbox.bottom + 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hud.won) {
      return;
    }

    dt = dt.clamp(0, GameConfig.maxDt);

    velocity.y += GameConfig.gravity * dt;
    if (velocity.y < 0 && !input.jumpHeld) {
      velocity.y +=
          GameConfig.gravity * (GameConfig.jumpReleaseGravity - 1) * dt;
    }
    if (velocity.y > GameConfig.maxFallSpeed) {
      velocity.y = GameConfig.maxFallSpeed;
    }

    _separateFromSolids();
    _probeWalls();
    _updateCoyote(dt);
    _updateHorizontal(dt);
    _tryJump();

    if (!_grounded &&
        (_touchingLeft || _touchingRight) &&
        velocity.y > GameConfig.wallSlideSpeed) {
      velocity.y = GameConfig.wallSlideSpeed;
    }

    _moveX(dt);
    hud.setHorizontalSpeed(velocity.x.abs());
    _moveY(dt);
    _probeWalls();
    _collectCoins();

    if (position.y > grid.level.worldHeight + GameConfig.deathMargin) {
      onDeath();
      return;
    }

    if (_grounded && !_wasGrounded) {
      scale.setValues(1.18, 0.82);
    }
    _wasGrounded = _grounded;

    scale
      ..x += (1 - scale.x) * dt * 14
      ..y += (1 - scale.y) * dt * 14;
  }

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

  void _updateHorizontal(double dt) {
    if (_grounded) {
      _airTime = 0;
      final surface = grid.surfaceBelow(_feetProbe);
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
      _takeoffSpeed = velocity.x.abs();
      return;
    }

    _airTime += dt;
    if (input.runHeld) {
      velocity.x =
          _facing * _takeoffSpeed * GameConfig.airSpeedFactor(_airTime);
    } else {
      velocity.x = PlayerRules.approach(
        velocity.x,
        0,
        GameConfig.runDecel,
        dt,
      );
    }
  }

  void _tryJump() {
    final canGroundJump = _grounded || _coyote > 0;
    final canWallJump = !canGroundJump &&
        (_touchingLeft || _touchingRight || _wallCoyote > 0);
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
    _takeoffSpeed = velocity.x.abs();
    _airTime = 0;
    _wallCoyote = 0;
    position.x += _facing * 2;
    _separateFromSolids();
    input.consumeJump();
    scale.setValues(0.82, 1.22);
  }

  void _separateFromSolids() {
    _resolveX();
    _resolveY();
    _clampX();
  }

  void _moveX(double dt) {
    position.x += velocity.x * dt;
    final attempted = position.x;
    _resolveX();
    if ((position.x - attempted).abs() > 0.001) {
      velocity.x = 0;
    }
    _clampX();
  }

  void _moveY(double dt) {
    _grounded = false;
    position.y += velocity.y * dt;
    final attempted = position.y;
    _resolveY();
    if (position.y < attempted - 0.001) {
      _grounded = true;
      if (velocity.y > 0) {
        velocity.y = 0;
      }
    } else if (position.y > attempted + 0.001) {
      if (velocity.y < 0) {
        velocity.y = 0;
      }
    }

    if (!_grounded) {
      _grounded = grid.overlapsSolid(_feetProbe);
      if (_grounded && velocity.y > 0) {
        velocity.y = 0;
      }
    }
  }

  void _resolveX() {
    position.x = grid.separateX(
      centerX: position.x,
      centerY: position.y,
      halfWidth: size.x / 2,
      halfHeight: size.y / 2,
      skin: GameConfig.skin,
    );
  }

  void _resolveY() {
    position.y = grid.separateY(
      centerX: position.x,
      centerY: position.y,
      halfWidth: size.x / 2,
      halfHeight: size.y / 2,
      skin: GameConfig.skin,
    );
  }

  void _clampX() {
    final halfW = size.x / 2;
    position.x = position.x.clamp(halfW, grid.level.worldWidth - halfW);
  }

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

  @override
  void render(Canvas canvas) {
    final body = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      _body,
    );
    final eye = _facing > 0
        ? Rect.fromLTWH(size.x - 10, 6, 6, 6)
        : Rect.fromLTWH(4, 6, 6, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(eye, const Radius.circular(1.5)),
      _eye,
    );
  }
}
