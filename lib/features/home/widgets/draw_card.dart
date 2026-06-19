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
    this.onTap,
    super.key,
  });

  final LotteryDrawModel draw;
  final String productName;
  final int index;
  final DateTime? lastUpdated;
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

    var ballAnimIndex = 0;

    final cardWidget = Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Product Badge & Draw ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? productCol.withValues(alpha: 0.25)
                          : productSoftCol,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: productCol.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      productDisplay,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : productCol,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${localizations.drawNumber}${draw.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
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

    if (index >= 8) {
      return cardWidget;
    }

    return cardWidget
        .animate()
        .fade(duration: 300.ms, delay: (index * 80).ms)
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 400.ms,
          delay: (index * 80).ms,
        );
  }
}
