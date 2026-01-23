import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'reveal_screen.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _glowAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/home_bg.png', fit: BoxFit.cover),
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
                  radius: 0.9,
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: child,
                                );
                              },
                              child: _LogoGlow(
                                glow: _glowAnimation,
                                maxWidth: constraints.maxWidth,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Avslöja bedragaren',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            Column(
                              children: [
                                _NeonButton(
                                  label: 'Starta spel',
                                  glow: _glowAnimation,
                                  gradient: const [
                                    AppTheme.neonCyan,
                                    AppTheme.neonMint,
                                  ],
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RevealScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                _NeonButton(
                                  label: 'Inställningar',
                                  glow: _glowAnimation,
                                  gradient: const [
                                    Color(0xFF3A5B85),
                                    Color(0xFF2A3C58),
                                  ],
                                  backgroundColor: AppTheme.panelSurfaceDeep,
                                  textColor: theme.colorScheme.onSurface,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
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

class _LogoGlow extends StatelessWidget {
  const _LogoGlow({required this.glow, required this.maxWidth});

  final Animation<double> glow;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final logoWidth = maxWidth.clamp(220, 360).toDouble() * 1.5;
    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.18 * glow.value),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/logo.png',
        width: logoWidth,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.glow,
    required this.gradient,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final Animation<double> glow;
  final List<Color> gradient;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(22);

    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        final glowStrength = 0.18 + (0.12 * glow.value);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: glowStrength),
                blurRadius: 20 + (8 * glow.value),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: gradient.last.withValues(alpha: glowStrength * 0.7),
                blurRadius: 28 + (10 * glow.value),
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Material(
            color: backgroundColor ?? AppTheme.panelSurface,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onPressed,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
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
