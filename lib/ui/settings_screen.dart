import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<TextEditingController> _controllers = [];
  final List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    setState(() {
      _controllers.add(_createController('Spelare ${_controllers.length + 1}'));
    });
    _savePlayers();
  }

  void _removePlayer(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
    _savePlayers();
  }

  TextEditingController _createController(String name) {
    final controller = TextEditingController(text: name);
    controller.addListener(_savePlayers);
    return controller;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPlayers = prefs.getStringList('players');
    final players = storedPlayers ?? _defaultPlayers();
    final categories = await _loadCategories();
    final storedCategory = prefs.getString('category');
    final selectedCategory = categories.contains(storedCategory)
        ? storedCategory
        : (categories.isNotEmpty ? categories.first : null);

    setState(() {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers
        ..clear()
        ..addAll(players.map(_createController));
      _categories
        ..clear()
        ..addAll(categories);
      _selectedCategory = selectedCategory;
      _isLoading = false;
    });
  }

  Future<List<String>> _loadCategories() async {
    try {
      final data = await rootBundle.loadString('assets/words/words.sv.json');
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        final categories = decoded.keys.toList()..sort();
        return categories;
      }
    } catch (_) {}
    return [];
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final players = _controllers.map((controller) => controller.text).toList();
    await prefs.setStringList('players', players);
  }

  Future<void> _saveCategory() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedCategory == null) {
      await prefs.remove('category');
    } else {
      await prefs.setString('category', _selectedCategory!);
    }
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _saveCategory();
  }

  List<String> _defaultPlayers() {
    return List.generate(4, (index) => 'Spelare ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inställningar')),
      body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Spelare',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      buildDefaultDragHandles: false,
                      itemCount: _controllers.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final controller = _controllers.removeAt(oldIndex);
                          _controllers.insert(newIndex, controller);
                        });
                        _savePlayers();
                      },
                      itemBuilder: (context, index) {
                        return _PlayerField(
                          key: ValueKey(_controllers[index]),
                          index: index,
                          controller: _controllers[index],
                          label: 'Spelare ${index + 1}',
                          canRemove: _controllers.length > 2,
                          onRemove: () => _removePlayer(index),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addPlayer,
                      icon: const Icon(Icons.add),
                      label: const Text('Lägg till spelare'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kategorier',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Välj vilken kategori som ska kunna dyka upp.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_categories.isEmpty)
                      Text(
                        'Inga kategorier hittades i ordlistan.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Kategori',
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: _selectCategory,
                      ),
                  ],
                ),
      ),
    );
  }
}

class _PlayerField extends StatelessWidget {
  const _PlayerField({
    super.key,
    required this.index,
    required this.controller,
    required this.label,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final String label;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Dra för att ändra ordning',
              child: ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ta bort spelare',
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
