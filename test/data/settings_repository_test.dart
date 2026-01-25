import 'package:flutter_test/flutter_test.dart';
import 'package:imposteur/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsRepository', () {
    late SettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = const SettingsRepository();
    });

    test('loadPlayers returns null when no players are saved', () async {
      final players = await repository.loadPlayers();
      expect(players, isNull);
    });

    test('savePlayers and loadPlayers works correctly', () async {
      final players = ['Alice', 'Bob', 'Charlie'];
      await repository.savePlayers(players);
      final loadedPlayers = await repository.loadPlayers();
      expect(loadedPlayers, equals(players));
    });

    test('saveCategory and loadCategory works correctly', () async {
      const category = 'animals';
      await repository.saveCategory(category);
      final loadedCategory = await repository.loadCategory();
      expect(loadedCategory, equals(category));
    });

    test('loadCategory returns null when no category is saved', () async {
      final category = await repository.loadCategory();
      expect(category, isNull);
    });

    test('saveCategory with null removes the category', () async {
      await repository.saveCategory('animals');
      await repository.saveCategory(null);
      final loadedCategory = await repository.loadCategory();
      expect(loadedCategory, isNull);
    });

    test('PlayerEntry serialization works', () {
      const entry = PlayerEntry(name: 'Test', avatarAsset: 'assets/test.png');
      final json = entry.toJson();
      expect(json['name'], 'Test');
      expect(json['avatarAsset'], 'assets/test.png');

      final parsed = PlayerEntry.fromJson(json);
      expect(parsed?.name, 'Test');
      expect(parsed?.avatarAsset, 'assets/test.png');
    });

    test('savePlayerEntries and loadPlayerEntries works correctly', () async {
      final entries = [
        const PlayerEntry(name: 'Alice', avatarAsset: 'assets/alice.png'),
        const PlayerEntry(name: 'Bob', avatarAsset: 'assets/bob.png'),
      ];
      await repository.savePlayerEntries(entries);
      final loadedEntries = await repository.loadPlayerEntries();

      expect(loadedEntries, isNotNull);
      expect(loadedEntries!.length, 2);
      expect(loadedEntries[0].name, 'Alice');
      expect(loadedEntries[0].avatarAsset, 'assets/alice.png');
      expect(loadedEntries[1].name, 'Bob');
      expect(loadedEntries[1].avatarAsset, 'assets/bob.png');
    });
  });
}
