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
    final Gradient gradient;
    if (isSpecial) {
      gradient = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)], // Vibrant gold to amber
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      gradient = LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF38BDF8),
                const Color(0xFF0284C7),
              ] // Slate mode sky blue
            : [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.85),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    final shadowColor = isSpecial
        ? const Color(0xFFD97706).withValues(alpha: 0.3)
        : (isDark ? const Color(0xFF0284C7) : theme.colorScheme.primary)
              .withValues(alpha: 0.2);

    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 3),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, -1),
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
          curve: Curves.easeOutBack,
          duration: 300.ms,
          delay: (index * 40).ms,
        );
  }
}
