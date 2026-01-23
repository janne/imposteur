import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  const SettingsRepository();

  Future<List<String>?> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('players');
  }

  Future<void> savePlayers(List<String> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('players', players);
  }

  Future<String?> loadCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('category');
  }

  Future<void> saveCategory(String? category) async {
    final prefs = await SharedPreferences.getInstance();
    if (category == null) {
      await prefs.remove('category');
    } else {
      await prefs.setString('category', category);
    }
  }
}
