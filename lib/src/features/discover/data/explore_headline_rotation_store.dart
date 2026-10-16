import 'package:shared_preferences/shared_preferences.dart';

const _key = 'explore.headline_rotation';

class ExploreHeadlineRotationStore {
  Future<int> next() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_key) ?? 0;
      await prefs.setInt(_key, current + 1);
      return current;
    } on Object {
      return 0;
    }
  }
}
