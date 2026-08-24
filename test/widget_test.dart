import 'package:flutter_test/flutter_test.dart';
import 'package:odd/app.dart';

void main() {
  testWidgets('menu lists bundled maps', (tester) async {
    await tester.pumpWidget(const OddApp());
    await tester.pumpAndSettle();

    expect(find.text('ODD'), findsOneWidget);
    expect(find.text('Warmup'), findsOneWidget);
    expect(find.text('Kick Turn'), findsOneWidget);
    expect(find.text('The Shaft'), findsOneWidget);
  });
}
