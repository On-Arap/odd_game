import 'package:shared_preferences/shared_preferences.dart';

/// Persistent tutorial step. Missing key is written as 0 on first launch.
class TutorialStore {
  static const key = 'tutorial_lvl';

  Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(key)) {
      await prefs.setInt(key, 0);
      return 0;
    }
    return prefs.getInt(key) ?? 0;
  }

  Future<void> save(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, level);
  }
}
