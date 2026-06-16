import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vietlott_data/features/home/product_history_page.dart';
import 'package:vietlott_data/features/home/suggestion_view.dart';
import 'package:vietlott_data/features/home/widgets/draw_card.dart';
import 'package:vietlott_data/features/home/widgets/shimmer_loading.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/crawler/crawler_service.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';
import 'package:vietlott_data/services/theme/app_themes.dart';

class DrawHistoryPage extends StatefulWidget {
  const DrawHistoryPage({super.key});

  @override
  State<DrawHistoryPage> createState() => _DrawHistoryPageState();
}

class _DrawHistoryPageState extends State<DrawHistoryPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [HomeView(), SuggestionView(), SettingsView()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: localizations.translate('appTitle'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            activeIcon: const Icon(Icons.auto_awesome),
            label: localizations.suggestions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: localizations.settings,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 1. HOME VIEW
// ----------------------------------------------------
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, List<LotteryDrawModel>> _productDraws = {};
  final LotteryRepository _lotteryRepo = LotteryRepository();

  final List<String> _products = SyncManager.instance.adapters
      .map((a) => a.productName)
      .toList();

  @override
  void initState() {
    super.initState();
    SyncManager.instance.init(_lotteryRepo);
    _loadAndSyncData();
  }

  Future<void> _loadAndSyncData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (forceRefresh) {
        for (final product in _products) {
          await SyncManager.instance.crawlLatestData(product);
        }
      } else {
        await SyncManager.instance.syncIfEmpty();
      }

      for (final product in _products) {
        final draws = await _lotteryRepo.getDraws(product, limit: 1);
        _productDraws[product] = draws;
      }

      if (!forceRefresh) {
        unawaited(_checkAndCrawlLatestInBackground());
      }
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAndCrawlLatestInBackground() async {
    for (final product in _products) {
      try {
        final lastUpdated = await _lotteryRepo.getLastUpdated(product);
        final shouldUpdate = lastUpdated == null ||
            DateTime.now().difference(lastUpdated).inHours >= 6;

        if (shouldUpdate) {
          unawaited(_crawlProductInBackground(product));
        }
      } catch (e) {
        print('Error in background update check for $product: $e');
      }
    }
  }

  Future<void> _crawlProductInBackground(String product) async {
    try {
      await SyncManager.instance.crawlLatestData(product);
      final draws = await _lotteryRepo.getDraws(product, limit: 1);
      if (mounted) {
        setState(() {
          _productDraws[product] = draws;
        });
      }
    } catch (e) {
      print('Background crawl error for $product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _loadAndSyncData(forceRefresh: true);
            },
            tooltip: localizations.reSync,
          ),
        ],
      ),
      body: _isLoading
          ? const ShimmerLoading()
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${localizations.errorOccurred}$_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _loadAndSyncData(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadAndSyncData(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      localizations.latestResults,

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  ..._products.expand((product) {
                    final draws = _productDraws[product] ?? [];
                    return draws.map((draw) {
                      return DrawCard(
                        draw: draw,
                        productName: product,
                        index:
                            _products.indexOf(product) * 3 +
                            draws.indexOf(draw),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ProductHistoryPage(productName: product),
                            ),
                          );
                        },
                      );
                    });
                  }),
                ],
              ),
            ),
    );
  }
}

// ----------------------------------------------------
// 2. SETTINGS VIEW
// ----------------------------------------------------
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsProvider.of(context);
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language section
          _buildSectionHeader(theme, localizations.language),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildRadioTile<String>(
                  context,
                  title: localizations.langVi,
                  value: 'vi',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    if (val != null) settings.setLocale(Locale(val));
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _buildRadioTile<String>(
                  context,
                  title: localizations.langEn,
                  value: 'en',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    if (val != null) settings.setLocale(Locale(val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme section
          _buildSectionHeader(theme, localizations.theme),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildRadioTile<AppThemeMode>(
                  context,
                  title: localizations.themeLightRed,
                  value: AppThemeMode.lightRed,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    if (val != null) settings.setThemeMode(val);
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _buildRadioTile<AppThemeMode>(
                  context,
                  title: localizations.themeDarkSlate,
                  value: AppThemeMode.darkSlate,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    if (val != null) settings.setThemeMode(val);
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _buildRadioTile<AppThemeMode>(
                  context,
                  title: localizations.themeGoldLuxury,
                  value: AppThemeMode.goldLuxury,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    if (val != null) settings.setThemeMode(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info section
          _buildSectionHeader(
            theme,
            localizations.appInfo,
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                localizations.appDisclaimer,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
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

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? theme.colorScheme.primary : Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () => onChanged(value),
    );
  }
}
