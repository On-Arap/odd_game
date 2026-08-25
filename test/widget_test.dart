import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odd/app.dart';
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
    await tester.pumpWidget(const OddApp());
    await tester.pumpAndSettle();

    expect(find.text('ODD'), findsOneWidget);
    expect(find.text('Jump Jump'), findsOneWidget);
    expect(find.text('Wall Jump'), findsOneWidget);
    expect(find.text('The Shaft'), findsOneWidget);
  });

  test('mapmaker route is web-only', () {
    expect(kIsWeb, isFalse);
    expect(OddApp.initialRoute(), '/');
  });

  testWidgets('mapmaker screen builds', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    expect(find.text('Map Maker'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Solid (#)'), findsOneWidget);
    expect(find.text('Coin (C)'), findsOneWidget);
  });

  testWidgets('export dialog loads pasted map json', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export').first);
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
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(find.text('Map loaded.'), findsOneWidget);
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

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.textContaining('needs exactly one player spawn'), findsOneWidget);
    expect(find.text('Map Maker'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('play then back keeps the edited map', (tester) async {
    await tester.pumpWidget(await _mapMakerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export').first);
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
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();
    expect(find.text('Map loaded.'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(MapMakerScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Play'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('EDITOR'), findsOneWidget);

    await tester.tap(find.text('EDITOR'));
    await tester.pumpAndSettle();

    expect(find.text('Map Maker'), findsOneWidget);
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
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Generate'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Export').first);
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
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(
      tester.element(find.byType(MapMakerScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(find.text('Validated 4.25'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Generate'))
          .onPressed,
      isNotNull,
    );
  });
}
