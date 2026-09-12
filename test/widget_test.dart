import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odd/app.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/tutorial_store.dart';
import 'package:odd/domain/level_map.dart';
import 'package:odd/ui/admin_screen.dart';
import 'package:odd/ui/game_screen.dart';
import 'package:odd/ui/mapmaker_preview.dart';
import 'package:odd/ui/mapmaker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _mapMakerApp() async {
  return MaterialApp(
    home: MapMakerScreen(assetsFuture: MapMakerAssets.placeholder()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('menu lists bundled maps', (tester) async {
    SharedPreferences.setMockInitialValues({TutorialStore.key: 1});
    await tester.pumpWidget(const OddApp());
    await tester.pumpAndSettle();

    expect(find.text(AppString.appTitle), findsOneWidget);
    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text(AppString.levelNumber(0)), findsOneWidget);
    expect(find.text(AppString.playLevel), findsOneWidget);
    expect(find.text('Folkin\' Around'), findsNothing);
    expect(find.text(AppString.defaultMapName), findsNothing);
    expect(find.byKey(const Key('tutorial-home-mask')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('campaign-tile-1')));
    await tester.pumpAndSettle();

    expect(find.text('Folkin\' Around'), findsOneWidget);
    expect(find.text(AppString.levelNumber(1)), findsOneWidget);
    expect(find.text('Tutorial'), findsNothing);

    await tester.tap(find.text('Rome'));
    await tester.pumpAndSettle();

    expect(find.text(AppString.dailyMap), findsWidgets);
    expect(find.text(AppString.levelNumber(1)), findsNothing);
    expect(find.byType(GameScreen), findsNothing);
  });

  test('mapmaker route is web-only', () {
    expect(kIsWeb, isFalse);
    expect(OddApp.initialRoute(), '/');
  });

  testWidgets('admin screen builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    await tester.pump();
    expect(find.text(AppString.admin), findsOneWidget);
  });

  testWidgets('mapmaker screen builds', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    expect(find.text(AppString.mapMaker), findsOneWidget);
    expect(find.text(AppString.generate), findsOneWidget);
    expect(find.text(AppString.export), findsOneWidget);
    expect(find.text(AppString.play), findsOneWidget);
    expect(
      find.text('${AppString.tileSolid} (${TileCodes.solid})'),
      findsOneWidget,
    );
    expect(
      find.text('${AppString.tileCoin} (${TileCodes.coin})'),
      findsOneWidget,
    );
  });

  testWidgets('export dialog loads pasted map json', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppString.export).first);
    await tester.pumpAndSettle();

    const json = '''
{
  "format": 1,
  "id": "test_map",
  "name": "Test Map",
  "tileSize": 16,
  "grid": [
    "###",
    "#P#",
    "###"
  ]
}
''';

    await tester.enterText(find.byKey(const Key('export-json-field')), json);
    await tester.tap(find.widgetWithText(FilledButton, AppString.export));
    await tester.pumpAndSettle();

    expect(find.text(AppString.mapLoaded), findsOneWidget);
    expect(find.text('test_map'), findsOneWidget);
    expect(find.text('Test Map'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('dragging on the grid paints a rectangle of blocks', (
    tester,
  ) async {
    var rect = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapMakerPreviewGrid(
            cols: 8,
            rows: 6,
            grid: List.generate(6, (_) => '.' * 8),
            brushColor: const Color(0xFFFFFFFF),
            onPaintRect: (col0, row0, col1, row1) {
              rect = [col0, row0, col1, row1];
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final grid = find.byType(MapMakerPreviewGrid);
    await tester.timedDragFrom(
      tester.getTopLeft(grid) + const Offset(8, 8),
      const Offset(40, 24),
      const Duration(milliseconds: 200),
    );
    await tester.pump();

    expect(rect, [0, 0, 3, 2]);
  });

  testWidgets('play on an unfinished map stays in the editor', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppString.play));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(AppString.levelNeedsSpawn('draft.json')),
      findsOneWidget,
    );
    expect(find.text(AppString.mapMaker), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('play then back keeps the edited map', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppString.export).first);
    await tester.pumpAndSettle();

    const json = '''
{
  "format": 1,
  "id": "playtest_map",
  "name": "Playtest Map",
  "tileSize": 16,
  "grid": [
    "###",
    "#P#",
    "#C#"
  ]
}
''';
    await tester.enterText(find.byKey(const Key('export-json-field')), json);
    await tester.tap(find.widgetWithText(FilledButton, AppString.export));
    await tester.pumpAndSettle();
    expect(find.text(AppString.mapLoaded), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(MapMakerScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, AppString.play));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text(AppString.editor), findsOneWidget);

    await tester.tap(find.text(AppString.editor));
    await tester.pumpAndSettle();

    expect(find.text(AppString.mapMaker), findsOneWidget);
    expect(find.text('playtest_map'), findsOneWidget);
    expect(find.text('Playtest Map'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('generate stays disabled until the map is validated', (
    tester,
  ) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, AppString.generate),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text(AppString.export).first);
    await tester.pumpAndSettle();

    const json = '''
{
  "format": 1,
  "id": "validated_map",
  "name": "Validated Map",
  "tileSize": 16,
  "author_time": 4.25,
  "grid": [
    "###",
    "#P#",
    "#C#"
  ]
}
''';
    await tester.enterText(find.byKey(const Key('export-json-field')), json);
    await tester.tap(find.widgetWithText(FilledButton, AppString.export));
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(
      tester.element(find.byType(MapMakerScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(find.text(AppString.validatedTime('4.250')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, AppString.generate),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, AppString.generate));
    await tester.pumpAndSettle();
    expect(find.text(AppString.copy), findsOneWidget);
    expect(find.text(AppString.upload), findsOneWidget);
  });
}
