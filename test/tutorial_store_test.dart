import 'package:flutter_test/flutter_test.dart';
import 'package:odd/data/tutorial_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first launch writes tutorial_lvl as 0', () async {
    final store = TutorialStore();
    expect(await store.load(), 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(TutorialStore.key), 0);
  });

  test('save persists the step', () async {
    final store = TutorialStore();
    await store.save(2);
    expect(await store.load(), 2);
  });
}
