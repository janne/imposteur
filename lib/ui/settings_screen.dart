import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<TextEditingController> _controllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
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
      _controllers.add(
        _createController('Spelare ${_controllers.length + 1}'),
      );
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

  Future<void> _loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPlayers = prefs.getStringList('players');
    final players = storedPlayers ?? _defaultPlayers();

    setState(() {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers
        ..clear()
        ..addAll(players.map(_createController));
      _isLoading = false;
    });
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final players = _controllers.map((controller) => controller.text).toList();
    await prefs.setStringList('players', players);
  }

  List<String> _defaultPlayers() {
    return List.generate(4, (index) => 'Spelare ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inställningar'),
      ),
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
                  for (var index = 0; index < _controllers.length; index++)
                    _PlayerField(
                      controller: _controllers[index],
                      label: 'Spelare ${index + 1}',
                      canRemove: _controllers.length > 2,
                      onRemove: () => _removePlayer(index),
                    ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add),
                    label: const Text('Lägg till spelare'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlayerField extends StatelessWidget {
  const _PlayerField({
    required this.controller,
    required this.label,
    required this.canRemove,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String label;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            IconButton(
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
