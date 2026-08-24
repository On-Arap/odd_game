import 'package:flutter_test/flutter_test.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/domain/player_rules.dart';
import 'package:odd/game/config.dart';

void main() {
  test('parses a rectangular grid with spawn and coins', () {
    const source = '''
{
  "format": 1,
  "id": "test",
  "name": "Test",
  "tileSize": 32,
  "grid": [
    "####",
    "#PC#",
    "####"
  ]
}
''';
    final level = LevelMap.parseJson(source, file: 'test.json');
    expect(level.cols, 4);
    expect(level.rows, 3);
    expect(level.spawn, const GridPos(1, 1));
    expect(level.coins, [const GridPos(2, 1)]);
    expect(level.isSolid(0, 1), isTrue);
    expect(level.isSolid(1, 1), isFalse);
    expect(level.isSolid(-1, 1), isTrue);
    expect(level.isSolid(1, 99), isFalse);
    expect(level.worldWidth, 128);
  });

  test('ice and mud tiles are solid', () {
    const source = '''
{
  "format": 1,
  "id": "surfaces",
  "name": "Surfaces",
  "tileSize": 32,
  "grid": [
    "####",
    "#PC#",
    "#IM#"
  ]
}
''';
    final level = LevelMap.parseJson(source, file: 'surfaces.json');
    expect(level.isSolid(1, 2), isTrue);
    expect(level.isSolid(2, 2), isTrue);
    expect(level.tileAt(1, 2), TileCodes.ice);
    expect(level.tileAt(2, 2), TileCodes.mud);
    expect(surfaceOf('I'), GroundSurface.ice);
    expect(surfaceOf('M'), GroundSurface.mud);
  });

  test('rejects unknown tiles and missing spawn', () {
    expect(
      () => LevelMap.parseJson(
        '{"format":1,"id":"x","name":"X","tileSize":32,"grid":["#X#"]}',
        file: 'bad.json',
      ),
      throwsFormatException,
    );
    expect(
      () => LevelMap.parseJson(
        '{"format":1,"id":"x","name":"X","tileSize":32,"grid":["#.C#"]}',
        file: 'bad.json',
      ),
      throwsFormatException,
    );
  });

  test('constant accel reaches max speed from rest in runAccelTime', () {
    expect(
      _approachFor(0, GameConfig.runSpeed, GameConfig.runAccel, GameConfig.runAccelTime),
      closeTo(GameConfig.runSpeed, 0.001),
    );
  });

  test('constant accel from half speed reaches max in half the time', () {
    expect(
      _approachFor(
        GameConfig.runSpeed / 2,
        GameConfig.runSpeed,
        GameConfig.runAccel,
        GameConfig.runAccelTime / 2,
      ),
      closeTo(GameConfig.runSpeed, 0.001),
    );
  });

  test('constant decel stops from max speed in runDecelTime', () {
    expect(
      _approachFor(GameConfig.runSpeed, 0, GameConfig.runDecel, GameConfig.runDecelTime),
      closeTo(0, 0.001),
    );
  });

  test('constant decel from half speed stops in half the time', () {
    expect(
      _approachFor(
        GameConfig.runSpeed / 2,
        0,
        GameConfig.runDecel,
        GameConfig.runDecelTime / 2,
      ),
      closeTo(0, 0.001),
    );
  });

  test('air speed uses takeoff speed, not max run speed', () {
    const takeoff = 100.0;
    expect(
      takeoff * GameConfig.airSpeedFactor(0),
      100,
    );
    expect(
      takeoff * GameConfig.airSpeedFactor(GameConfig.airFullSpeedTime),
      100,
    );
    expect(
      takeoff * GameConfig.airSpeedFactor(
        GameConfig.airFullSpeedTime + GameConfig.airDecayTime,
      ),
      takeoff * GameConfig.airMinSpeedFactor,
    );
  });

  test('wall jump flips away from the wall', () {
    expect(
      PlayerRules.facingAfterWallJump(
        facing: 1,
        touchingLeft: false,
        touchingRight: true,
        lastWall: 1,
      ),
      -1,
    );
    expect(
      PlayerRules.facingAfterWallJump(
        facing: -1,
        touchingLeft: true,
        touchingRight: false,
        lastWall: -1,
      ),
      1,
    );
  });
}

double _approachFor(
  double start,
  double target,
  double rate,
  double duration,
) {
  var speed = start;
  var time = 0.0;
  const dt = 1 / 60;
  while (time < duration) {
    speed = PlayerRules.approach(speed, target, rate, dt);
    time += dt;
  }
  return speed;
}
