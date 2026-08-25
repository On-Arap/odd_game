import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odd/app.dart';
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
}
