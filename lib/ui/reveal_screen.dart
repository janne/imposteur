import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  final Random _random = Random();
  final Map<String, List<String>> _wordMap = {};
  final List<String> _players = [];
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
  String? _category;
  String _word = '';
  int _impostorIndex = 0;
  int _currentIndex = 0;
  int _startingPlayerIndex = 0;
  int _roundId = 0;
  bool _showStartingPlayer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPlayers = prefs.getStringList('players');
    final players = _normalizePlayers(storedPlayers ?? _defaultPlayers());
    final storedCategory = prefs.getString('category');
    final words = await _loadWords();
    final categories = words.keys.toList()..sort();
    final category = categories.contains(storedCategory)
        ? storedCategory
        : (categories.isNotEmpty ? categories.first : null);

    if (!mounted) {
      return;
    }

    setState(() {
      _wordMap
        ..clear()
        ..addAll(words);
      _players
        ..clear()
        ..addAll(players);
      _category = category;
      _isLoading = false;
    });

    _startNewRound();
  }

  Future<Map<String, List<String>>> _loadWords() async {
    try {
      final data = await rootBundle.loadString('assets/words/words.sv.json');
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        final result = <String, List<String>>{};
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is List) {
            result[entry.key] = value.whereType<String>().toList();
          }
        }
        return result;
      }
    } catch (_) {}
    return {};
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

  List<String> _defaultPlayers() {
    return List.generate(4, (index) => 'Spelare ${index + 1}');
  }

  String _avatarForIndex(int index) {
    return _avatarAssets[index % _avatarAssets.length];
  }

  void _startNewRound() {
    if (_players.isEmpty || _wordMap.isEmpty || _category == null) {
      return;
    }
    final words = _wordMap[_category] ?? [];
    if (words.isEmpty) {
      return;
    }
    setState(() {
      _word = words[_random.nextInt(words.length)];
      _impostorIndex = _random.nextInt(_players.length);
      _currentIndex = 0;
      _startingPlayerIndex = _random.nextInt(_players.length);
      _showStartingPlayer = false;
      _roundId += 1;
    });
  }

  void _nextPlayer() {
    if (_currentIndex < _players.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
      return;
    }
    setState(() {
      _showStartingPlayer = true;
      _startingPlayerIndex = _random.nextInt(_players.length);
      _roundId += 1;
    });
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
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.25),
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
                  radius: 1.1,
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
                : _wordMap.isEmpty
                ? Center(
                    child: Text(
                      'Inga ord hittades. Kontrollera ordlistan.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _BackButtonPill(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                _StatusPill(
                                  label: _showStartingPlayer
                                      ? 'Startar nu'
                                      : 'Spelare ${_currentIndex + 1}/${_players.length}',
                                  icon: _showStartingPlayer
                                      ? Icons.play_arrow_rounded
                                      : Icons.people_alt_rounded,
                                ),
                              ],
                            ),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                    maxHeight: 520,
                                  ),
                                  child: _showStartingPlayer
                                      ? _buildStartingPlayer(theme)
                                      : _buildRevealCard(theme),
                                ),
                              ),
                            ),
                            if (!_showStartingPlayer)
                              _HintPanel(
                                icon: Icons.touch_app_rounded,
                                label: 'Håll inne för att avslöja ordet.',
                              ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              label: _showStartingPlayer
                                  ? 'Nytt spel'
                                  : (_currentIndex == _players.length - 1)
                                  ? 'Börja spelet'
                                  : 'Nästa spelare',
                              onPressed: _showStartingPlayer
                                  ? _startNewRound
                                  : _nextPlayer,
                              isPrimary: !_showStartingPlayer,
                            ),
                            SizedBox(height: constraints.maxHeight * 0.02),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealCard(ThemeData theme) {
    final playerName = _players[_currentIndex];
    final isImpostor = _currentIndex == _impostorIndex;
    final accentColor = isImpostor ? AppTheme.neonRed : AppTheme.neonMint;
    final back = _RevealCardFace(
      title: isImpostor ? 'Du är förrädaren' : _word,
      subtitle: isImpostor ? 'Kategori · ${_category ?? 'Okänd'}' : 'Kategori',
      helper: isImpostor ? 'Håll masken och improvisera.' : _category ?? ' ',
      accentColor: accentColor,
      icon: isImpostor ? Icons.visibility_off_rounded : Icons.auto_awesome,
      emphasize: true,
    );

    return AspectRatio(
      aspectRatio: 2.6 / 3.6,
      child: _HoldToRevealCard(
        key: ValueKey('reveal-$_roundId-$_currentIndex'),
        front: _RevealCardFace(
          title: playerName,
          subtitle: 'Spelare ${_currentIndex + 1}',
          helper: 'Håll inne för att avslöja.',
          accentColor: AppTheme.neonCyan,
          avatarAsset: _avatarForIndex(_currentIndex),
        ),
        back: back,
      ),
    );
  }

  Widget _buildStartingPlayer(ThemeData theme) {
    final playerName = _players[_startingPlayerIndex];
    return _RevealCardFace(
      title: playerName,
      subtitle: 'börjar spelet',
      helper: 'Starta diskussionen när alla sett sitt ord.',
      accentColor: AppTheme.neonMint,
      avatarAsset: _avatarForIndex(_startingPlayerIndex),
      icon: Icons.play_circle_fill_rounded,
      emphasize: true,
    );
  }
}

class _RevealCardFace extends StatelessWidget {
  const _RevealCardFace({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.helper,
    this.icon,
    this.avatarAsset,
    this.emphasize = false,
  });

  final String title;
  final String subtitle;
  final String? helper;
  final IconData? icon;
  final Color accentColor;
  final String? avatarAsset;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        (emphasize
                ? theme.textTheme.headlineMedium
                : theme.textTheme.headlineSmall)
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4);
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
    final helperStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [AppTheme.panelSurface, AppTheme.panelSurfaceDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avatarSize = constraints.maxWidth * 0.55;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
              if (icon != null) const SizedBox(height: 16),
              if (avatarAsset != null)
                Container(
                  height: avatarSize,
                  width: avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(avatarAsset!, fit: BoxFit.cover),
                  ),
                ),
              if (avatarAsset != null) const SizedBox(height: 20),
              Text(title, textAlign: TextAlign.center, style: titleStyle),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: subtitleStyle),
              if (helper != null) ...[
                const SizedBox(height: 12),
                Text(helper!, textAlign: TextAlign.center, style: helperStyle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.neonCyan),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panelSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.neonCyan),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(20);
    final gradient = isPrimary
        ? const [AppTheme.neonCyan, AppTheme.neonMint]
        : const [AppTheme.neonOrange, AppTheme.neonRed];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Material(
        color: AppTheme.panelSurfaceDeep,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldToRevealCard extends StatefulWidget {
  const _HoldToRevealCard({super.key, required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<_HoldToRevealCard> createState() => _HoldToRevealCardState();
}

class _HoldToRevealCardState extends State<_HoldToRevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showBack() {
    _controller.forward();
  }

  void _showFront() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _showBack(),
      onPointerUp: (_) => _showFront(),
      onPointerCancel: (_) => _showFront(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final showingFront = angle <= (pi / 2);
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: showingFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}
