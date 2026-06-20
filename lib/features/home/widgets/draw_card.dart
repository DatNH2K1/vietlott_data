import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vietlott_data/features/home/widgets/ball_widget.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';

class DrawCard extends StatelessWidget {
  const DrawCard({
    required this.draw,
    required this.productName,
    required this.index,
    this.lastUpdated,
    this.jackpot,
    this.onTap,
    super.key,
  });

  final LotteryDrawModel draw;
  final String productName;
  final int index;
  final DateTime? lastUpdated;
  final int? jackpot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    // Get display name & colors of the product
    final String productDisplay;
    final Color productCol;
    final Color productSoftCol;

    if (productName == 'power535') {
      productDisplay = 'Power 5/35';
      productCol = const Color(0xFFFF8F00); // Amber/Orange
      productSoftCol = const Color(0xFFFF8F00).withValues(alpha: 0.1);
    } else if (productName == 'power655') {
      productDisplay = 'Power 6/55';
      productCol = const Color(0xFFDC2626); // Red
      productSoftCol = const Color(0xFFDC2626).withValues(alpha: 0.1);
    } else {
      productDisplay = 'Mega 6/45';
      productCol = const Color(0xFF1E88E5); // Blue
      productSoftCol = const Color(0xFF1E88E5).withValues(alpha: 0.1);
    }

    // Date formatting helper
    String formatDate(String rawDate) {
      try {
        final parts = rawDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      } catch (_) {}
      return rawDate;
    }

    // Last updated formatting helper
    String formatLastUpdated(DateTime dt) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$hour:$minute $day/$month';
    }

    // Jackpot formatting helper
    String formatJackpot(int val) {
      if (val >= 1000000000) {
        final billions = val / 1000000000;
        return '${billions.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} Tỷ VNĐ';
      }
      return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ';
    }

    var ballAnimIndex = 0;

    final cardWidget = Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFF1EFE9),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Product Badge & Draw ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? productCol.withValues(alpha: 0.2)
                          : productSoftCol,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: productCol.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      productDisplay,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : productCol,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Text(
                    '${localizations.drawNumber}${draw.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (jackpot != null && jackpot! > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF2D220C),
                              const Color(0xFF1E1404),
                            ]
                          : [
                              const Color(0xFFFEF3C7),
                              const Color(0xFFFDE68A),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          size: 18,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JACKPOT ESTIMATE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFFF5E0A3) : const Color(0xFFB58920),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatJackpot(jackpot!),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 2.seconds,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.3),
                ),
              ],
              const SizedBox(height: 16),

              // Middle Row: Winning Balls
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Regular Balls
                  ...draw.regular.map((val) {
                    final widget = BallWidget(
                      number: val,
                      isSpecial: false,
                      index: ballAnimIndex,
                      size: 38,
                    );
                    ballAnimIndex++;
                    return widget;
                  }),

                  // Separator if special exists
                  if (draw.special.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        '|',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),

                  // Special Balls
                  ...draw.special.map((val) {
                    final widget = BallWidget(
                      number: val,
                      isSpecial: true,
                      index: ballAnimIndex,
                      size: 38,
                    );
                    ballAnimIndex++;
                    return widget;
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Row: Date & Last Updated
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDate(draw.date),
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (lastUpdated != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync_outlined,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${localizations.lastUpdated}${formatLastUpdated(lastUpdated!)}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    var animatedCard = cardWidget
        .animate()
        .fade(duration: 300.ms, delay: (index * 80).ms)
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 400.ms,
          delay: (index * 80).ms,
        );

    if (jackpot != null && jackpot! > 0) {
      animatedCard = animatedCard
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .boxShadow(
            begin: BoxShadow(
              color: productCol.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
            end: BoxShadow(
              color: productCol.withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: 1.5,
            ),
            duration: 2500.ms,
            curve: Curves.easeInOut,
          );
    }

    return animatedCard;
  }
}
