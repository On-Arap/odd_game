import 'package:flutter_test/flutter_test.dart';
import 'package:odd/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
