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
  static String nicknameTitle = 'Choose a nickname';
  static String nicknameHint = '3–16 letters, numbers, _';
  static String nicknameTaken = 'That nickname is taken.';
  static String nicknameTooShort = 'At least 3 characters.';
  static String nicknameTooLong = '16 characters max.';
  static String nicknameBadChars = 'Use letters, numbers or _.';
  static String nicknameSave = 'SAVE';
  static String onlineProfileError(Object error) =>
      'Online profile failed.\n$error';
  static String leaderboardEmpty = 'No times yet.';
  static String leaderboardLoadError = 'Could not load the leaderboard.';
  static String myRank(int rank, String formatted) =>
      'Your rank : $rank, Your time : $formatted';

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
  static String playLevel = 'PLAY';
  static String levelNumber(int index) =>
      '#${(index + 1).toString().padLeft(2, '0')}';
  static String generate = 'Generate';
  static String close = 'Close';
  static String copy = 'Copy';
  static String upload = 'Upload';
  static String bronzeTime = 'Bronze time';
  static String silverTime = 'Silver time';
  static String goldTime = 'Gold time';
  static String medalTimesHint = 'Medal times in seconds';
  static String invalidMedalTime = 'Medal times must be empty or a number ≥ 0.';
  static String cancel = 'Cancel';
  static String confirm = 'CONFIRM';
  static String overwrite = 'OVERWRITE';
  static String mapUploaded = 'Map uploaded.';
  static String mapUploadNeedBackend = 'Supabase is not configured.';
  static String mapUploadFailed(Object error) => 'Upload failed.\n$error';
  static String mapOverwriteTitle = 'Overwrite this map?';
  static String mapOverwriteBody(String name, int times) {
    final timesLine = times == 1
        ? '1 recorded time will be deleted.'
        : '$times recorded times will be deleted.';
    return '"$name" already exists on the server.\n'
        'This will replace the map data.\n'
        '$timesLine';
  }

  static String mapJson = 'Map JSON';
  static String pasteMapJson = 'Paste map JSON here…';
  static String mapLoaded = 'Map loaded.';
  static String jsonCopied = 'JSON copied to clipboard';
  static String generateHint = 'Complete the map in Play to generate JSON.';
  static String playBeforeGenerate =
      'Play and complete the map before generating.';
  static String sizeMustBePositive =
      'Width and height must be positive numbers.';
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
  static String levelUnknownTile(String file, String cell, int col, int row) =>
      'Level $file has unknown tile "$cell" at ($col, $row). '
      'Use . # I M P C';
  static String levelNeedsSpawn(String file) =>
      'Level $file needs exactly one player spawn (P).';
  static String levelNeedsCoin(String file) =>
      'Level $file needs at least one coin (C).';

  static String admin = 'Admin';
  static String adminCampaign = 'Campaign maps';
  static String adminCampaignHint =
      'Check maps to add them. Order is the order you check them (15 max).';
  static String adminAddMap = 'Add map';
  static String adminDaily = 'Daily map';
  static String adminNoDaily = 'None';
  static String adminValidate = 'VALIDATE';
  static String adminSaved = 'Content saved.';
  static String adminTooManyMaps = '15 maps maximum.';
  static String adminNoMaps =
      'No maps in map_data yet. Upload one from Map Maker.';
  static String adminDanger = 'Danger zone';
  static String adminDeleteMap = 'Delete map';
  static String adminDeleteMapTimes = 'Delete times for this map';
  static String adminDeleteAllTimes = 'Delete all times';
  static String adminDeleteAllUsers = 'Delete all users';
  static String adminConfirmTitle = 'Are you sure?';
  static String adminConfirmDeleteMap(String name) =>
      'Delete "$name" and every recorded time on it? This cannot be undone.';
  static String adminConfirmMapTimes(String name) =>
      'Delete every recorded time on "$name"?';
  static String adminConfirmAllTimes =
      'Delete every recorded time in the game?';
  static String adminConfirmAllUsers =
      'Delete every user, profile, and recorded time? This cannot be undone.';
  static String adminDeletedMap(int count) => count == 0
      ? 'Map deleted.'
      : count == 1
      ? 'Map deleted, and 1 time.'
      : 'Map deleted, and $count times.';
  static String adminDeletedTimes(int count) =>
      count == 1 ? 'Deleted 1 time.' : 'Deleted $count times.';
  static String adminDeletedUsers(int count) =>
      count == 1 ? 'Deleted 1 user.' : 'Deleted $count users.';
  static String adminFailed(Object error) => 'Admin action failed.\n$error';
}
