/// Textes du jeu, modifiables à la volée (`AppString.menu = '…'`).
class AppString {
  AppString._();

  static String appTitle = 'ODD';

  static String menuTagline = 'Grab every coin. Fastest time wins.';
  static String dailyMap = 'DailyMap';
  static String noTime = '—';
  static String mapsLoadError(Object error) => 'Could not load maps.\n$error';
  static String totalTime(String formatted) => 'Total $formatted';

  static String menu = 'MENU';
  static String editor = 'EDITOR';
  static String retry = 'RETRY';
  static String next = 'NEXT';
  static String ok = 'OK';

  static String clear = 'CLEAR';
  static String personalBest = 'PERSONAL BEST :';
  static String authorGem = 'Author Gem';
  static String personalBestShort(String formatted) => 'PB $formatted';

  static String holdToRun = 'Hold to run';
  static String pressToJump = 'Press to Jump';
  static String jumpHoldHint = '(The longer, the higher)';
  static String doubleJumpTitle = 'Double Jump :';
  static String doubleJumpBody =
      'While airborn, you can press Jump again to do a double jump';
  static String walljumpTitle = 'Walljump :';
  static String walljumpBody =
      'Press Jump while against a wall to walljump, and turn around';
  static String medalsTutorialBody =
      'Now, try to grab all the coin in a level\nto finish it.\nthere\'s 3 Medal to unlock in each map,\nand if you try hard enought, there\'s an Author Gem\nGood luck';

  static String mapMaker = 'Map Maker';
  static String width = 'Width';
  static String height = 'Height';
  static String apply = 'Apply';
  static String mapId = 'Map id';
  static String mapName = 'Map name';
  static String defaultMapId = 'new_map';
  static String defaultMapName = 'New Map';
  static String export = 'Export';
  static String play = 'Play';
  static String generate = 'Generate';
  static String close = 'Close';
  static String copy = 'Copy';
  static String mapJson = 'Map JSON';
  static String pasteMapJson = 'Paste map JSON here…';
  static String mapLoaded = 'Map loaded.';
  static String jsonCopied = 'JSON copied to clipboard';
  static String generateHint = 'Complete the map in Play to generate JSON.';
  static String playBeforeGenerate =
      'Play and complete the map before generating.';
  static String sizeMustBePositive = 'Width and height must be positive numbers.';
  static String expectedJsonObject = 'Expected a JSON object.';
  static String missingGrid = 'Missing a non-empty "grid".';
  static String gridRowsMustBeStrings = 'Grid rows must be strings.';
  static String emptyGridRow = 'Grid rows cannot be empty.';
  static String invalidJson = 'Invalid JSON.';
  static String tileEmpty = 'Empty';
  static String tileSolid = 'Solid';
  static String tileIce = 'Ice';
  static String tileMud = 'Mud';
  static String tilePlayer = 'Player';
  static String tileCoin = 'Coin';
  static String spritesLoadError(Object error) =>
      'Could not load sprites: $error';
  static String gridMinSize(int min) =>
      'Grid width and height must be at least $min.';
  static String unevenRow(int row) => 'Row $row has uneven width.';
  static String unknownTile(String cell, int col, int row) =>
      'Unknown tile "$cell" at ($col, $row). Use . # I M P C.';
  static String validatedTime(String formatted) => 'Validated $formatted';

  static String levelNotJsonObject(String file) =>
      'Level $file must be a JSON object.';
  static String levelUnsupportedFormat(String file, Object? format) =>
      'Level $file has unsupported format "$format". Expected 1.';
  static String levelMissingId(String file) =>
      'Level $file is missing a string "id".';
  static String levelMissingName(String file) =>
      'Level $file is missing a string "name".';
  static String levelMissingTileSize(String file) =>
      'Level $file is missing a positive "tileSize".';
  static String levelMissingGrid(String file) =>
      'Level $file is missing a non-empty "grid".';
  static String levelInvalidAuthorTime(String file) =>
      'Level $file has an invalid "author_time".';
  static String levelInvalidBronzeTime(String file) =>
      'Level $file has an invalid "bronze_time".';
  static String levelInvalidSilverTime(String file) =>
      'Level $file has an invalid "silver_time".';
  static String levelInvalidGoldTime(String file) =>
      'Level $file has an invalid "gold_time".';
  static String levelGridRowsMustBeStrings(String file) =>
      'Level $file grid rows must be strings.';
  static String levelEmptyFirstRow(String file) =>
      'Level $file has an empty first grid row.';
  static String levelUnevenRow(String file, int row, int width, int expected) =>
      'Level $file row $row is $width wide, expected $expected.';
  static String levelMultipleSpawns(String file) =>
      'Level $file has more than one player spawn (P).';
  static String levelUnknownTile(
    String file,
    String cell,
    int col,
    int row,
  ) =>
      'Level $file has unknown tile "$cell" at ($col, $row). '
      'Use . # I M P C';
  static String levelNeedsSpawn(String file) =>
      'Level $file needs exactly one player spawn (P).';
  static String levelNeedsCoin(String file) =>
      'Level $file needs at least one coin (C).';
}
