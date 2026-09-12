import 'package:flutter_test/flutter_test.dart';
import 'package:odd/data/level_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads bundled campaign maps when supabase is not ready', () async {
    final levels = await LevelRepository().loadAll();
    expect(levels, isNotEmpty);
    expect(levels.first.id, 'tutorial');
    expect(levels.first.name, 'Tutorial');
  });

  test('loads bundled daily map when supabase is not ready', () async {
    final daily = await LevelRepository().loadDaily();
    expect(daily.id, 'Rome');
    expect(daily.name, 'Rome');
  });

  test('catalog id comparison is order-sensitive', () {
    expect(LevelRepository.sameIds(['a', 'b'], ['a', 'b']), isTrue);
    expect(LevelRepository.sameIds(['a', 'b'], ['b', 'a']), isFalse);
    expect(LevelRepository.sameIds(['a'], ['a', 'b']), isFalse);
    expect(
      LevelRepository.payloadIds([
        {'id': 'a'},
        {'name': 'no-id'},
        {'id': 'b'},
      ]),
      ['a', 'b'],
    );
  });
}
