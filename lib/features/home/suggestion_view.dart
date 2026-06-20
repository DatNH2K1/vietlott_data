import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vietlott_data/features/home/widgets/ball_widget.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';
import 'package:vietlott_data/services/suggestion/suggestion_engine.dart';

class SuggestionView extends StatefulWidget {
  const SuggestionView({super.key});

  @override
  State<SuggestionView> createState() => _SuggestionViewState();
}

class _SuggestionViewState extends State<SuggestionView> {
  final SuggestionEngine _engine = SuggestionEngine();
  String _selectedProduct = 'mega645';
  bool _isGenerating = false;
  List<int>? _suggestedNumbers;
  Map<String, dynamic>? _aiEvalResults;
  bool _isEvaluatingAi = false;

  @override
  void initState() {
    super.initState();
    _loadAiPerformance();
  }

  Future<void> _loadAiPerformance() async {
    setState(() {
      _isEvaluatingAi = true;
      _aiEvalResults = null;
    });
    try {
      final results = await _engine.evaluateAiPerformance(
        product: _selectedProduct,
        backTestCount: 200,
      );
      if (mounted) {
        setState(() {
          _aiEvalResults = results;
          _isEvaluatingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEvaluatingAi = false;
        });
      }
    }
  }

  Future<void> _generate() async {
    await HapticFeedback.heavyImpact();
    setState(() {
      _isGenerating = true;
      _suggestedNumbers = null;
    });

    // Simulate analysis delay for premium feel
    await Future<void>.delayed(1200.ms);

    try {
      final results = await _engine.generateSuggestions(
        product: _selectedProduct,
      );
      if (mounted) {
        setState(() {
          _suggestedNumbers = results;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorOccurred}$e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final products = [
      {'id': 'mega645', 'name': 'Mega 6/45', 'desc': localizations.mega645Desc},
      {
        'id': 'power655',
        'name': 'Power 6/55',
        'desc': localizations.power655Desc,
      },
      {
        'id': 'power535',
        'name': 'Lotto 5/35',
        'desc': localizations.power535Desc,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.suggestionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Product Selection Tab Bar
            _buildSectionHeader(localizations.selectProduct),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF151821).withValues(alpha: 0.8)
                    : const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF222F43).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: products.map((p) {
                  final isSelected = _selectedProduct == p['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedProduct = p['id']!;
                          _suggestedNumbers = null;
                        });
                        _loadAiPerformance();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            p['name']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // 2. ML Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.mlModelTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.mlModelDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .boxShadow(
                  begin: BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.02),
                    blurRadius: 4,
                  ),
                  end: BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 14,
                  ),
                  duration: 2500.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),

            // 3. Suggestions Result or Action Button
            if (_isGenerating)
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        localizations.analyzingMl,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_suggestedNumbers != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        localizations.suggestedNumbers,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_suggestedNumbers!.isEmpty)
                        Text(
                          localizations.noDataToAnalyze,
                          style: const TextStyle(color: Colors.red),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(_suggestedNumbers!.length, (
                            index,
                          ) {
                            final number = _suggestedNumbers![index];
                            final isPower535Special =
                                _selectedProduct == 'power535' && index >= 5;
                            final isPower655Special =
                                _selectedProduct == 'power655' && index >= 6;
                            return BallWidget(
                              number: number,
                              isSpecial: isPower535Special || isPower655Special,
                              index: index,
                              size: 46,
                            );
                          }),
                        ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _generate,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          localizations.regenerate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOutQuad,
                duration: 350.ms,
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    localizations.generate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 2500.ms,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
            const SizedBox(height: 24),
            _buildTheoreticalProbabilitiesSection(localizations, theme, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTheoreticalProbabilitiesSection(
      AppLocalizations localizations, ThemeData theme, bool isDark) {
    final adapter = _engine.getAdapter(_selectedProduct);
    if (adapter == null) return const SizedBox.shrink();

    final probs = adapter.calculateWinningProbabilities();
    if (probs.isEmpty) return const SizedBox.shrink();

    final aiStats = (_aiEvalResults != null && _aiEvalResults!['stats'] != null)
        ? Map<String, int>.from(_aiEvalResults!['stats'] as Map)
        : <String, int>{};

    final totalEvaluated = _aiEvalResults != null ? _aiEvalResults!['totalEvaluated'] as int : 0;
    final avgMatches = _aiEvalResults != null ? _aiEvalResults!['averageMatches'] as double : 0.0;
    final maxMatches = adapter.numbersToSelect;



    final theoreticalRoi = adapter.theoreticalRoi;
    final actualRoi = (_aiEvalResults != null && _aiEvalResults!['roi'] != null)
        ? _aiEvalResults!['roi'] as double
        : 0.0;
    final formattedTheoreticalRoi = '${(theoreticalRoi * 100).toStringAsFixed(1)}%';
    final formattedActualRoi = _isEvaluatingAi
        ? '...'
        : '${(actualRoi * 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(localizations.theoreticalProbabilities),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            ),
          ),
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.roiRate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.translateWithParam(
                              'roiTheoretical',
                              'rate',
                              formattedTheoreticalRoi,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            localizations.translateWithParam(
                              'roiAiActual',
                              'rate',
                              formattedActualRoi,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: actualRoi > theoreticalRoi
                                  ? Colors.green
                                  : (isDark ? Colors.grey[350] : Colors.grey[750]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 300.ms),
        const SizedBox(height: 14),
        ...probs.entries.map((entry) {
          final prizeKey = entry.key;
          final probVal = entry.value;
          final formattedProb = _formatProbability(probVal);
          final prizeName = localizations.translate('prize_$prizeKey');

          final actualCount = aiStats[prizeKey] ?? 0;
          final isJackpot = prizeKey.contains('jackpot');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? (isJackpot 
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : const Color(0xFF151821).withValues(alpha: 0.6))
                  : (isJackpot 
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? (isJackpot
                        ? theme.colorScheme.primary.withValues(alpha: 0.4)
                        : const Color(0xFF222F43).withValues(alpha: 0.5))
                    : (isJackpot
                        ? theme.colorScheme.primary.withValues(alpha: 0.25)
                        : const Color(0xFFE2E8F0)),
                width: isJackpot ? 1.5 : 1,
              ),
              boxShadow: isJackpot
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Icon representing the prize tier
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPrizeIconColor(prizeKey, theme).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getPrizeIcon(prizeKey),
                    color: _getPrizeIconColor(prizeKey, theme),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Prize details and probability
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prizeName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${localizations.theoreticalColumn}: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                          Text(
                            formattedProb,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // AI actual winning count badge
                if (_isEvaluatingAi)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: actualCount > 0
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: actualCount == 0
                              ? (isDark
                                  ? const Color(0xFF222F43)
                                  : const Color(0xFFE2E8F0))
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: actualCount > 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (actualCount > 0) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              totalEvaluated > 0
                                  ? '$actualCount / $totalEvaluated'
                                  : '0 / 0',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: actualCount > 0
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ).animate().fade(duration: 350.ms).slideX(
                begin: 0.05,
                curve: Curves.easeOutQuad,
              );
        }),
        const SizedBox(height: 12),
        // AI Backtest summary card
        if (!_isEvaluatingAi && totalEvaluated > 0)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
              ),
            ),
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: CircularProgressIndicator(
                          value: avgMatches / maxMatches,
                          backgroundColor: isDark
                              ? const Color(0xFF222F43)
                              : const Color(0xFFE2E8F0),
                          color: theme.colorScheme.secondary,
                          strokeWidth: 4.5,
                        ),
                      ),
                      Text(
                        avgMatches.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translateWithParam(
                            'aiPerformance',
                            'count',
                            '$totalEvaluated',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${localizations.translateWithParam('averageMatchesPerDraw', 'avg', '${avgMatches.toStringAsFixed(2)} / $maxMatches')} • ${localizations.translateWithParam('lastNDraws', 'count', '$totalEvaluated')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 400.ms),
      ],
    );
  }

  IconData _getPrizeIcon(String prizeKey) {
    if (prizeKey.contains('jackpot')) {
      return Icons.emoji_events_rounded;
    }
    switch (prizeKey) {
      case 'first':
        return Icons.looks_one_rounded;
      case 'second':
        return Icons.looks_two_rounded;
      case 'third':
        return Icons.looks_3_rounded;
      case 'fourth':
        return Icons.looks_4_rounded;
      case 'fifth':
        return Icons.looks_5_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  Color _getPrizeIconColor(String prizeKey, ThemeData theme) {
    if (prizeKey.contains('jackpot')) {
      return Colors.amber[700]!;
    }
    switch (prizeKey) {
      case 'first':
        return theme.colorScheme.primary;
      case 'second':
        return Colors.blueGrey[600]!;
      case 'third':
        return Colors.brown[600]!;
      default:
        return theme.colorScheme.secondary;
    }
  }

  String _formatProbability(double prob) {
    if (prob <= 0) return '0';
    if (prob >= 1.0) return '1';
    final denominator = (1.0 / prob).round();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedDenominator = denominator
        .toString()
        .replaceAllMapped(reg, (Match match) => '${match[1]},');
    return '1 / $formattedDenominator';
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
