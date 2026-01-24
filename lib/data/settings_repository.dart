import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlayerEntry {
  const PlayerEntry({required this.name, required this.avatarAsset});

  final String name;
  final String avatarAsset;

  Map<String, dynamic> toJson() {
    return {'name': name, 'avatarAsset': avatarAsset};
  }

  static PlayerEntry? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final name = json['name'];
    final avatarAsset = json['avatarAsset'];
    if (name is! String || avatarAsset is! String) {
      return null;
    }
    return PlayerEntry(name: name, avatarAsset: avatarAsset);
  }
}

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

  Future<List<PlayerEntry>?> loadPlayerEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('player_entries');
    if (stored == null || stored.isEmpty) {
      return null;
    }
    final entries = <PlayerEntry>[];
    for (final entry in stored) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          final parsed = PlayerEntry.fromJson(decoded);
          if (parsed != null) {
            entries.add(parsed);
          }
        }
      } catch (_) {}
    }
    return entries.isEmpty ? null : entries;
  }

  Future<void> savePlayerEntries(List<PlayerEntry> players) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = players
        .map((player) => jsonEncode(player.toJson()))
        .toList();
    await prefs.setStringList('player_entries', encoded);
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
