import 'dart:convert';

/// Grid characters the upcoming web editor should emit.
abstract final class TileCodes {
  static const empty = '.';
  static const solid = '#';
  static const ice = 'I';
  static const mud = 'M';
  static const player = 'P';
  static const coin = 'C';

  /// `#`, `I` et `M` bloquent le joueur.
  static bool isSolid(String cell) {
    return cell == solid || cell == ice || cell == mud;
  }
}

enum GroundSurface { none, solid, ice, mud }

/// Type de sol sous les pieds (vitesse, glisse).
GroundSurface surfaceOf(String cell) {
  switch (cell) {
    case TileCodes.ice:
      return GroundSurface.ice;
    case TileCodes.mud:
      return GroundSurface.mud;
    case TileCodes.solid:
      return GroundSurface.solid;
    default:
      return GroundSurface.none;
  }
}

class GridPos {
  const GridPos(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => '($col, $row)';
}

/// Immutable level data. Flame never owns this — it only reads it.
class LevelMap {
  const LevelMap({
    required this.format,
    required this.id,
    required this.name,
    required this.file,
    required this.tileSize,
    required this.grid,
    required this.spawn,
    required this.coins,
    this.authorTime,
  });

  final int format;
  final String id;
  final String name;
  final String file;
  final double tileSize;
  final List<String> grid;
  final GridPos spawn;
  final List<GridPos> coins;
  final double? authorTime;

  int get cols => grid.first.length;
  int get rows => grid.length;
  double get worldWidth => cols * tileSize;
  double get worldHeight => rows * tileSize;
  int get coinCount => coins.length;

  /// Hors carte : murs infinis à gauche/droite/haut ; le vide en bas se traverse.
  bool isSolid(int col, int row) {
    if (col < 0 || col >= cols || row < 0) {
      return true;
    }
    if (row >= rows) {
      return false;
    }
    return TileCodes.isSolid(grid[row][col]);
  }

  /// Caractère de la case, ou mur / vide hors limites.
  String tileAt(int col, int row) {
    if (col < 0 || col >= cols || row < 0) {
      return TileCodes.solid;
    }
    if (row >= rows) {
      return TileCodes.empty;
    }
    return grid[row][col];
  }

  /// Parse le JSON texte d'un fichier de map.
  factory LevelMap.parseJson(
    String source, {
    required String file,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Level $file must be a JSON object.');
    }
    return LevelMap.fromJson(decoded, file: file);
  }

  /// Valide le JSON, trouve P et les C, construit le [LevelMap].
  factory LevelMap.fromJson(
    Map<String, dynamic> json, {
    required String file,
  }) {
    final format = json['format'];
    if (format != 1) {
      throw FormatException(
        'Level $file has unsupported format "$format". Expected 1.',
      );
    }

    final id = json['id'];
    final name = json['name'];
    final tileSize = json['tileSize'];
    final gridRaw = json['grid'];
    final authorTimeRaw = json['author_time'];

    if (id is! String || id.isEmpty) {
      throw FormatException('Level $file is missing a string "id".');
    }
    if (name is! String || name.isEmpty) {
      throw FormatException('Level $file is missing a string "name".');
    }
    if (tileSize is! num || tileSize <= 0) {
      throw FormatException('Level $file is missing a positive "tileSize".');
    }
    if (gridRaw is! List || gridRaw.isEmpty) {
      throw FormatException('Level $file is missing a non-empty "grid".');
    }
    if (authorTimeRaw != null &&
        (authorTimeRaw is! num || authorTimeRaw < 0)) {
      throw FormatException('Level $file has an invalid "author_time".');
    }

    final grid = gridRaw.map((row) {
      if (row is! String) {
        throw FormatException('Level $file grid rows must be strings.');
      }
      return row;
    }).toList();

    final cols = grid.first.length;
    if (cols == 0) {
      throw FormatException('Level $file has an empty first grid row.');
    }
    // Toutes les lignes doivent avoir la même largeur.
    for (var r = 0; r < grid.length; r++) {
      if (grid[r].length != cols) {
        throw FormatException(
          'Level $file row $r is ${grid[r].length} wide, expected $cols.',
        );
      }
    }

    GridPos? spawn;
    final coins = <GridPos>[];

    // Un seul P, au moins un C, tuiles connues seulement.
    for (var row = 0; row < grid.length; row++) {
      for (var col = 0; col < cols; col++) {
        final cell = grid[row][col];
        switch (cell) {
          case TileCodes.empty:
          case TileCodes.solid:
          case TileCodes.ice:
          case TileCodes.mud:
            break;
          case TileCodes.player:
            if (spawn != null) {
              throw FormatException(
                'Level $file has more than one player spawn (P).',
              );
            }
            spawn = GridPos(col, row);
          case TileCodes.coin:
            coins.add(GridPos(col, row));
          default:
            throw FormatException(
              'Level $file has unknown tile "$cell" at ($col, $row). '
              'Use . # I M P C',
            );
        }
      }
    }

    if (spawn == null) {
      throw FormatException('Level $file needs exactly one player spawn (P).');
    }
    if (coins.isEmpty) {
      throw FormatException('Level $file needs at least one coin (C).');
    }

    return LevelMap(
      format: format as int,
      id: id,
      name: name,
      file: file,
      tileSize: tileSize.toDouble(),
      grid: grid,
      spawn: spawn,
      coins: coins,
      authorTime: authorTimeRaw == null
          ? null
          : (authorTimeRaw as num).toDouble(),
    );
  }
}
