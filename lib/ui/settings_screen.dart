import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings_repository.dart';
import 'app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _settingsRepository = const SettingsRepository();
  final List<TextEditingController> _controllers = [];
  final List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  static const int _minPlayers = 3;
  static const int _maxPlayers = 12;
  static const List<String> _avatarAssets = [
    'assets/avatars/red.png',
    'assets/avatars/orange.png',
    'assets/avatars/yellow.png',
    'assets/avatars/green.png',
    'assets/avatars/cyan.png',
    'assets/avatars/blue.png',
    'assets/avatars/purple.png',
    'assets/avatars/pink.png',
    'assets/avatars/brown.png',
    'assets/avatars/grey.png',
    'assets/avatars/white.png',
    'assets/avatars/black.png',
  ];

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
    if (_controllers.length >= _maxPlayers) {
      return;
    }
    setState(() {
      _controllers.add(_createController('Spelare ${_controllers.length + 1}'));
    });
    _savePlayers();
  }

  void _removePlayer(int index) {
    if (_controllers.length <= _minPlayers) {
      return;
    }
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
    final storedPlayers = await _settingsRepository.loadPlayers();
    final players = _normalizePlayers(storedPlayers ?? _defaultPlayers());
    final categories = await _loadCategories();
    final storedCategory = await _settingsRepository.loadCategory();
    final selectedCategory = categories.contains(storedCategory) ? storedCategory : (categories.isNotEmpty ? categories.first : null);

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
    final players = _controllers.map((controller) => controller.text).toList();
    await _settingsRepository.savePlayers(players);
  }

  Future<void> _saveCategory() async {
    await _settingsRepository.saveCategory(_selectedCategory);
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

  List<String> _normalizePlayers(List<String> players) {
    final normalized = <String>[];
    for (var index = 0; index < players.length; index++) {
      final name = players[index].trim();
      normalized.add(name.isEmpty ? 'Spelare ${index + 1}' : name);
    }
    final safePlayers = normalized.isEmpty ? _defaultPlayers() : normalized;
    final limited = safePlayers.take(_maxPlayers).toList();
    if (limited.length >= _minPlayers) {
      return limited;
    }
    return List.generate(_minPlayers, (index) => index < limited.length ? limited[index] : 'Spelare ${index + 1}');
  }

  String _avatarForIndex(int index) {
    return _avatarAssets[index % _avatarAssets.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/bg.png', fit: BoxFit.cover)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.72), Colors.black.withValues(alpha: 0.35), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [AppTheme.neonCyan.withValues(alpha: 0.14), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _BackButtonPill(
                                      onPressed: () {
                                        Navigator.of(context).maybePop();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Inställningar',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ställ in spelare och välj ordkategori innan ni drar igång.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                                ),
                                const SizedBox(height: 24),
                                const _SectionHeader(title: 'Kategorier', subtitle: 'Välj en kategori som ska användas i spelet.'),
                                const SizedBox(height: 12),
                                _SettingsPanel(
                                  child: _categories.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text('Inga kategorier hittades i ordlistan.', style: theme.textTheme.bodyMedium),
                                        )
                                      : DropdownButtonFormField<String>(
                                          initialValue: _selectedCategory,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppTheme.panelSurfaceDeep,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.4),
                                            ),
                                            labelText: 'Kategori',
                                          ),
                                          dropdownColor: AppTheme.panelSurface,
                                          items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                                          onChanged: _selectCategory,
                                        ),
                                ),
                                const SizedBox(height: 28),
                                _SectionHeader(title: 'Spelare', subtitle: '${_controllers.length} av $_maxPlayers · Min $_minPlayers spelare'),
                                const SizedBox(height: 12),
                                _SettingsPanel(
                                  child: ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(top: 6, bottom: 6),
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
                                        avatarAsset: _avatarForIndex(index),
                                        canRemove: _controllers.length > _minPlayers,
                                        onRemove: () => _removePlayer(index),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _GlowButton(
                                  label: 'Lägg till spelare',
                                  icon: Icons.add,
                                  onPressed: _controllers.length >= _maxPlayers ? null : _addPlayer,
                                ),
                                if (_controllers.length >= _maxPlayers)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      'Max $_maxPlayers spelare. Ta bort någon för att lägga till fler.',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                SizedBox(height: constraints.maxHeight * 0.08),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panelSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class _BackButtonPill extends StatelessWidget {
  const _BackButtonPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panelSurface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back, size: 18), SizedBox(width: 6), Text('Tillbaka')]),
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    final borderRadius = BorderRadius.circular(18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(colors: [AppTheme.neonCyan, AppTheme.neonMint], begin: Alignment.centerLeft, end: Alignment.centerRight)
            : null,
        borderRadius: borderRadius,
        boxShadow: isEnabled ? [BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 10))] : null,
      ),
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isEnabled ? AppTheme.panelSurfaceDeep : AppTheme.panelSurface,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              ],
            ),
          ),
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
    required this.avatarAsset,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final String label;
  final String avatarAsset;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.panelSurfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Tooltip(
              message: 'Dra för att ändra ordning',
              child: ReorderableDragStartListener(
                index: index,
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 6))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(avatarAsset, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ta bort spelare',
              onPressed: canRemove ? onRemove : null,
              icon: Icon(Icons.close, color: canRemove ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
