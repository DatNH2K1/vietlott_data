import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BallWidget extends StatelessWidget {
  const BallWidget({
    required this.number,
    required this.isSpecial,
    required this.index,
    this.size = 42,
    super.key,
  });

  final int number;
  final bool isSpecial;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberStr = number.toString().padLeft(2, '0');

    // Premium gradients based on type and theme mode
    final RadialGradient gradient;
    if (isSpecial) {
      gradient = const RadialGradient(
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFEAB308),
          Color(0xFF854D0E),
        ],
        center: Alignment(-0.3, -0.3),
        focal: Alignment(-0.1, -0.1),
        radius: 0.65,
      );
    } else {
      gradient = RadialGradient(
        colors: isDark
            ? const [
                Color(0xFFBAE6FD),
                Color(0xFF0284C7),
                Color(0xFF075985),
              ]
            : [
                const Color(0xFFFECDD3),
                theme.colorScheme.primary,
                const Color(0xFF881337),
              ],
        center: const Alignment(-0.3, -0.3),
        focal: const Alignment(-0.1, -0.1),
        radius: 0.65,
      );
    }

    final shadowColor = isSpecial
        ? const Color(0xFFD97706).withValues(alpha: 0.35)
        : (isDark ? const Color(0xFF0284C7) : theme.colorScheme.primary)
              .withValues(alpha: 0.25);

    var animatedWidget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: const Offset(0.5, 0.5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              numberStr,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 250.ms, delay: (index * 40).ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 600.ms,
          delay: (index * 40).ms,
        );

    if (isSpecial) {
      animatedWidget = animatedWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 1500.ms,
            curve: Curves.easeInOut,
          );
    }

    return animatedWidget;
  }
}
