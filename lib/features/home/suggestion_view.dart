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
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
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
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            p['name']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
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
                              fontWeight: FontWeight.bold,
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
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
              ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  localizations.generate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
