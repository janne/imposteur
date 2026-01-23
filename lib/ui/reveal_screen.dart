import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  final Random _random = Random();
  final Map<String, List<String>> _wordMap = {};
  final List<String> _players = [];
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
    return normalized.isEmpty ? _defaultPlayers() : normalized;
  }

  List<String> _defaultPlayers() {
    return List.generate(4, (index) => 'Spelare ${index + 1}');
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
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
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Avsluta spelet',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 420,
                              maxHeight: 420,
                            ),
                            child: _showStartingPlayer
                                ? _buildStartingPlayer(theme)
                                : _buildRevealCard(theme),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_showStartingPlayer)
                        Text(
                          'Tryck på kortet för att se ordet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _showStartingPlayer
                              ? _startNewRound
                              : _nextPlayer,
                          child: Text(
                            _showStartingPlayer
                                ? 'Nytt spel'
                                : (_currentIndex == _players.length - 1)
                                ? 'Börja spelet'
                                : 'Nästa spelare',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRevealCard(ThemeData theme) {
    final playerName = _players[_currentIndex];
    final isImpostor = _currentIndex == _impostorIndex;
    final back = _cardFace(
      theme,
      title: isImpostor ? 'Du är förrädaren' : _word,
      subtitle: _category ?? 'Kategori',
      icon: isImpostor ? Icons.visibility_off_rounded : Icons.auto_awesome,
      emphasize: true,
      backgroundColor: Colors.white,
      backgroundGradient: null,
      borderColor: null,
      titleColor: const Color(0xFF0B1424),
      subtitleColor: const Color(0xFF20324D),
      iconColor: const Color(0xFF0B1424),
    );

    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final borderWidth = constraints.maxWidth * 0.05;
          final front = _cardFace(
            theme,
            title: playerName,
            subtitle: 'Spelare ${_currentIndex + 1}',
            icon: Icons.person_rounded,
            borderColor: Colors.white.withValues(alpha: 0.9),
            borderWidth: borderWidth,
          );

          return _HoldToRevealCard(
            key: ValueKey('reveal-$_roundId-$_currentIndex'),
            front: front,
            back: back,
          );
        },
      ),
    );
  }

  Widget _buildStartingPlayer(ThemeData theme) {
    final playerName = _players[_startingPlayerIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_fill_rounded,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            playerName,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'börjar spelet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardFace(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    bool emphasize = false,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? borderColor,
    double? borderWidth,
    Color? titleColor,
    Color? subtitleColor,
    Color? iconColor,
    List<BoxShadow>? boxShadow,
  }) {
    final baseTitleStyle = emphasize
        ? theme.textTheme.headlineMedium
        : theme.textTheme.headlineSmall;
    final titleStyle = baseTitleStyle?.copyWith(
      fontWeight: FontWeight.w700,
      color: titleColor,
    );
    final fallbackGradient = LinearGradient(
      colors: [
        theme.colorScheme.surface,
        theme.colorScheme.surfaceContainerHighest,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final resolvedGradient =
        backgroundGradient ??
        (backgroundColor == null ? fallbackGradient : null);
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: resolvedGradient == null
            ? (backgroundColor ?? theme.colorScheme.surface)
            : null,
        gradient: resolvedGradient,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: borderWidth ?? 1.2),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: titleStyle),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: subtitleStyle),
        ],
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
