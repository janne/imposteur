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

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final SettingsRepository _settingsRepository = const SettingsRepository();
  final List<_PlayerSlot> _players = [];
  final List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
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
    _glowController = AnimationController(
      vsync: this,
      duration: AppAnimations.glowPulseDuration,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: AppAnimations.glowCurve),
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _glowController.dispose();
    for (final player in _players) {
      player.controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_players.length >= _maxPlayers) {
      return;
    }
    setState(() {
      _players.add(
        _createPlayerSlot(
          'Spelare ${_players.length + 1}',
          _nextAvailableAvatar(),
        ),
      );
    });
    _savePlayers();
  }

  void _removePlayer(int index) {
    if (_players.length <= _minPlayers) {
      return;
    }
    setState(() {
      _players[index].controller.dispose();
      _players.removeAt(index);
    });
    _savePlayers();
  }

  _PlayerSlot _createPlayerSlot(String name, String avatarAsset) {
    final controller = TextEditingController(text: name);
    controller.addListener(_savePlayers);
    return _PlayerSlot(controller: controller, avatarAsset: avatarAsset);
  }

  Future<void> _loadSettings() async {
    final storedEntries = await _settingsRepository.loadPlayerEntries();
    final storedPlayers = storedEntries == null
        ? await _settingsRepository.loadPlayers()
        : null;
    final players = _normalizePlayerEntries(storedEntries, storedPlayers);
    final categories = await _loadCategories();
    final storedCategory = await _settingsRepository.loadCategory();
    final selectedCategory = categories.contains(storedCategory)
        ? storedCategory
        : (categories.isNotEmpty ? categories.first : null);

    if (!mounted) {
      return;
    }

    setState(() {
      for (final player in _players) {
        player.controller.dispose();
      }
      _players
        ..clear()
        ..addAll(
          players.map(
            (entry) => _createPlayerSlot(entry.name, entry.avatarAsset),
          ),
        );
      _categories
        ..clear()
        ..addAll(categories);
      _selectedCategory = selectedCategory;
      _isLoading = false;
    });

    if (storedEntries == null) {
      await _settingsRepository.savePlayerEntries(players);
    }
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
    final entries = <PlayerEntry>[];
    for (var index = 0; index < _players.length; index++) {
      final name = _players[index].controller.text.trim();
      entries.add(
        PlayerEntry(
          name: name.isEmpty ? 'Spelare ${index + 1}' : name,
          avatarAsset: _players[index].avatarAsset,
        ),
      );
    }
    await _settingsRepository.savePlayerEntries(entries);
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
    return List.generate(
      _minPlayers,
      (index) =>
          index < limited.length ? limited[index] : 'Spelare ${index + 1}',
    );
  }

  List<PlayerEntry> _normalizePlayerEntries(
    List<PlayerEntry>? storedEntries,
    List<String>? legacyPlayers,
  ) {
    if (storedEntries != null && storedEntries.isNotEmpty) {
      return _normalizeEntryList(storedEntries);
    }
    final names = _normalizePlayers(legacyPlayers ?? _defaultPlayers());
    return _entriesFromNames(names);
  }

  List<PlayerEntry> _normalizeEntryList(List<PlayerEntry> entries) {
    final normalized = <PlayerEntry>[];
    final used = <String>{};
    for (
      var index = 0;
      index < entries.length && normalized.length < _maxPlayers;
      index++
    ) {
      final entry = entries[index];
      final name = entry.name.trim();
      var avatarAsset = entry.avatarAsset.trim();
      if (avatarAsset.isEmpty || used.contains(avatarAsset)) {
        avatarAsset = _nextAvailableAvatar(used);
      }
      used.add(avatarAsset);
      normalized.add(
        PlayerEntry(
          name: name.isEmpty ? 'Spelare ${index + 1}' : name,
          avatarAsset: avatarAsset,
        ),
      );
    }
    if (normalized.length < _minPlayers) {
      for (var index = normalized.length; index < _minPlayers; index++) {
        final avatar = _nextAvailableAvatar(used);
        used.add(avatar);
        normalized.add(
          PlayerEntry(name: 'Spelare ${index + 1}', avatarAsset: avatar),
        );
      }
    }
    return normalized;
  }

  List<PlayerEntry> _entriesFromNames(List<String> names) {
    final entries = <PlayerEntry>[];
    final used = <String>{};
    for (var index = 0; index < names.length; index++) {
      final avatar = _nextAvailableAvatar(used);
      used.add(avatar);
      entries.add(PlayerEntry(name: names[index], avatarAsset: avatar));
    }
    return entries;
  }

  String _nextAvailableAvatar([Set<String>? used]) {
    final usedAvatars =
        used ?? _players.map((player) => player.avatarAsset).toSet();
    for (final asset in _avatarAssets) {
      if (!usedAvatars.contains(asset)) {
        return asset;
      }
    }
    return _avatarAssets[usedAvatars.length % _avatarAssets.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
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
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
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
                                      glow: _glowAnimation,
                                      onPressed: () {
                                        Navigator.of(context).maybePop();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Inställningar',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ställ in spelare och välj ordkategori innan ni drar igång.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const _SectionHeader(
                                  title: 'Kategorier',
                                  subtitle:
                                      'Välj en kategori som ska användas i spelet.',
                                ),
                                const SizedBox(height: 12),
                                _SettingsPanel(
                                  glow: _glowAnimation,
                                  child: _categories.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            'Inga kategorier hittades i ordlistan.',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        )
                                      : DropdownButtonFormField<String>(
                                          initialValue: _selectedCategory,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor:
                                                AppTheme.panelSurfaceDeep,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: theme
                                                    .colorScheme
                                                    .outlineVariant,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: theme
                                                    .colorScheme
                                                    .outlineVariant,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: AppTheme.neonCyan,
                                                width: 1.4,
                                              ),
                                            ),
                                            labelText: 'Kategori',
                                          ),
                                          dropdownColor: AppTheme.panelSurface,
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
                                ),
                                const SizedBox(height: 28),
                                _SectionHeader(
                                  title: 'Spelare',
                                  subtitle:
                                      '${_players.length} av $_maxPlayers · Min $_minPlayers spelare',
                                ),
                                const SizedBox(height: 12),
                                _SettingsPanel(
                                  glow: _glowAnimation,
                                  child: ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      bottom: 6,
                                    ),
                                    buildDefaultDragHandles: false,
                                    itemCount: _players.length,
                                    onReorder: (oldIndex, newIndex) {
                                      setState(() {
                                        if (newIndex > oldIndex) {
                                          newIndex -= 1;
                                        }
                                        final player = _players.removeAt(
                                          oldIndex,
                                        );
                                        _players.insert(newIndex, player);
                                      });
                                      _savePlayers();
                                    },
                                    itemBuilder: (context, index) {
                                      final player = _players[index];
                                      return _PlayerField(
                                        key: ValueKey(player.controller),
                                        index: index,
                                        controller: player.controller,
                                        label: 'Spelare ${index + 1}',
                                        avatarAsset: player.avatarAsset,
                                        canRemove:
                                            _players.length > _minPlayers,
                                        onRemove: () => _removePlayer(index),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _GlowButton(
                                  label: 'Lägg till spelare',
                                  icon: Icons.add,
                                  glow: _glowAnimation,
                                  onPressed: _players.length >= _maxPlayers
                                      ? null
                                      : _addPlayer,
                                ),
                                if (_players.length >= _maxPlayers)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      'Max $_maxPlayers spelare. Ta bort någon för att lägga till fler.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
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

class _PlayerSlot {
  _PlayerSlot({required this.controller, required this.avatarAsset});

  final TextEditingController controller;
  final String avatarAsset;
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
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child, this.glow});

  final Widget child;
  final Animation<double>? glow;

  @override
  Widget build(BuildContext context) {
    if (glow == null) {
      return _buildPanel(context, 1, child);
    }
    return AnimatedBuilder(
      animation: glow!,
      builder: (context, child) => _buildPanel(context, glow!.value, child!),
      child: child,
    );
  }

  Widget _buildPanel(BuildContext context, double glowValue, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.panelSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.08 + (0.05 * glowValue)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.08 * glowValue),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BackButtonPill extends StatefulWidget {
  const _BackButtonPill({required this.onPressed, this.glow});

  final VoidCallback onPressed;
  final Animation<double>? glow;

  @override
  State<_BackButtonPill> createState() => _BackButtonPillState();
}

class _BackButtonPillState extends State<_BackButtonPill> {
  bool _isPressed = false;

  void _handleHighlight(bool value) {
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    final glow = widget.glow;

    Widget content = Material(
      color: AppTheme.panelSurface.withValues(alpha: 0.85),
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: widget.onPressed,
        onHighlightChanged: _handleHighlight,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 18),
              SizedBox(width: 6),
              Text('Tillbaka'),
            ],
          ),
        ),
      ),
    );

    if (glow != null) {
      content = AnimatedBuilder(
        animation: glow,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.08 * glow.value),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: content,
      );
    }

    return AnimatedScale(
      duration: AppAnimations.pressDuration,
      scale: _isPressed ? 0.96 : 1,
      child: content,
    );
  }
}

class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.glow,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Animation<double>? glow;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _isPressed = false;

  void _handleHighlight(bool value) {
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null;
    final borderRadius = BorderRadius.circular(18);
    final animation = widget.glow ?? const AlwaysStoppedAnimation<double>(1);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glowValue = isEnabled ? animation.value : 0;
        final pulseScale = isEnabled ? (1.0 + (0.012 * glowValue)) : 1.0;
        return AnimatedScale(
          duration: AppAnimations.pressDuration,
          scale: _isPressed ? 0.97 : 1,
          child: Transform.scale(
            scale: pulseScale,
            child: Container(
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? const LinearGradient(
                        colors: [AppTheme.neonCyan, AppTheme.neonMint],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                borderRadius: borderRadius,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(
                            alpha: 0.18 + (0.12 * glowValue),
                          ),
                          blurRadius: 18.0 + (6.0 * glowValue),
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: Material(
                color: isEnabled
                    ? AppTheme.panelSurfaceDeep
                    : AppTheme.panelSurface,
                borderRadius: borderRadius,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: widget.onPressed,
                  onHighlightChanged: _handleHighlight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
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
                        border: Border.all(
                          color: AppTheme.neonCyan.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ta bort spelare',
              onPressed: canRemove ? onRemove : null,
              icon: Icon(
                Icons.close,
                color: canRemove
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
