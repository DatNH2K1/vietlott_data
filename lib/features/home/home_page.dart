import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vietlott_data/features/home/product_history_page.dart';
import 'package:vietlott_data/features/home/suggestion_view.dart';
import 'package:vietlott_data/features/home/widgets/battery_optimization_dialog.dart';
import 'package:vietlott_data/features/home/widgets/draw_card.dart';
import 'package:vietlott_data/features/home/widgets/shimmer_loading.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/background/background_sync_service.dart';
import 'package:vietlott_data/services/crawler/crawler_service.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';
import 'package:vietlott_data/services/settings/battery_optimization_service.dart';
import 'package:vietlott_data/services/theme/app_themes.dart';
import 'package:vietlott_data/services/update/update_service.dart';

class DrawHistoryPage extends StatefulWidget {
  const DrawHistoryPage({super.key});

  @override
  State<DrawHistoryPage> createState() => _DrawHistoryPageState();
}

class _DrawHistoryPageState extends State<DrawHistoryPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await UpdateService.instance.checkAndShowUpdateDialog(context);
      await _checkBatteryAndSync();
    });
  }

  Future<void> _checkBatteryAndSync() async {
    final isIgnoring = await BatteryOptimizationService.instance.isIgnoringBatteryOptimizations();
    if (isIgnoring) {
      await BackgroundSyncService.instance.register6HourPeriodicTask();
    } else {
      await BackgroundSyncService.instance.cancelPeriodicTask();
      final shouldPrompt = await BatteryOptimizationService.instance.shouldPromptForBatteryOptimization();
      if (shouldPrompt && mounted) {
        await BatteryOptimizationService.instance.markPrompted();
        if (!mounted) return;
        await BatteryOptimizationDialog.show(
          context,
          onConfirm: () async {
            await BatteryOptimizationService.instance.requestIgnoreBatteryOptimizations();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeView(
            onNavigateToTab: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          const SuggestionView(),
          const SettingsView(),
        ],
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
  const HomeView({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, List<LotteryDrawModel>> _productDraws = {};
  final Map<String, DateTime?> _productLastUpdated = {};
  final Map<String, int?> _productJackpots = {};
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
        await SyncManager.instance.syncJackpots();
        for (final product in _products) {
          await SyncManager.instance.crawlLatestData(product);
        }
      } else {
        await SyncManager.instance.syncIfEmpty();
        await SyncManager.instance.syncJackpots();
      }

      for (final product in _products) {
        final draws = await _lotteryRepo.getDraws(product, limit: 1);
        _productDraws[product] = draws;
        final lastUpdated = await _lotteryRepo.getLastUpdated(product);
        _productLastUpdated[product] = lastUpdated;
        _productJackpots[product] = await _lotteryRepo.getJackpot(product);
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
    var jackpotsSynced = false;
    for (final product in _products) {
      try {
        final lastUpdated = await _lotteryRepo.getLastUpdated(product);
        final shouldUpdate =
            lastUpdated == null ||
            DateTime.now().difference(lastUpdated).inHours >= 6;

        if (shouldUpdate) {
          if (!jackpotsSynced) {
            await SyncManager.instance.syncJackpots();
            jackpotsSynced = true;
          }
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
      final lastUpdated = await _lotteryRepo.getLastUpdated(product);
      final jackpot = await _lotteryRepo.getJackpot(product);
      if (mounted) {
        setState(() {
          _productDraws[product] = draws;
          _productLastUpdated[product] = lastUpdated;
          _productJackpots[product] = jackpot;
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // 1. Jackpot Spotlight PageView
                  _buildJackpotSpotlight(context),

                  // 2. Quick Actions
                  _buildQuickActions(context)
                      .animate()
                      .fade(duration: 400.ms, delay: 100.ms)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 400.ms,
                        delay: 100.ms,
                      ),
                  const SizedBox(height: 24),

                  // 3. Recent Results List
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 20),
                    child: Text(
                      localizations.latestResults,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  )
                      .animate()
                      .fade(duration: 400.ms, delay: 180.ms)
                      .slideX(
                        begin: -0.06,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 400.ms,
                        delay: 180.ms,
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _products.expand((product) {
                        final draws = _productDraws[product] ?? [];
                        final lastUpdated = _productLastUpdated[product];
                        final jackpot = _productJackpots[product];
                        return draws.map((draw) {
                          return DrawCard(
                            draw: draw,
                            productName: product,
                            lastUpdated: lastUpdated,
                            jackpot: jackpot,
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
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildJackpotSpotlight(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final spotlightItems = <Map<String, dynamic>>[];
    for (final product in _products) {
      final draws = _productDraws[product] ?? [];
      if (draws.isNotEmpty) {
        final latestDraw = draws.first;
        final jackpot = _productJackpots[product] ?? 0;
        if (jackpot > 0) {
          spotlightItems.add({
            'product': product,
            'draw': latestDraw,
            'jackpot': jackpot,
          });
        }
      }
    }

    if (spotlightItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: spotlightItems.length,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (context, index) {
              final item = spotlightItems[index];
              final product = item['product'] as String;
              final draw = item['draw'] as LotteryDrawModel;
              final jackpot = item['jackpot'] as int;

              final String displayTitle;
              final Color accentColor;
              if (product == 'power655') {
                displayTitle = 'Power 6/55';
                accentColor = const Color(0xFFDC2626);
              } else if (product == 'power535') {
                displayTitle = 'Lotto 5/35';
                accentColor = const Color(0xFFFF8F00);
              } else {
                displayTitle = 'Mega 6/45';
                accentColor = const Color(0xFF1E88E5);
              }

              var jackpotStr = '';
              if (jackpot >= 1000000000) {
                final billions = jackpot / 1000000000;
                jackpotStr = '${billions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} TỶ VNĐ';
              } else {
                final millions = jackpot / 1000000;
                jackpotStr = '${millions.toStringAsFixed(0)} TR VNĐ';
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            accentColor.withValues(alpha: 0.25),
                            const Color(0xFF151821),
                          ]
                        : [
                            accentColor.withValues(alpha: 0.15),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.3)
                        : accentColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductHistoryPage(productName: product),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                displayTitle.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  color: accentColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Kỳ quay #${draw.id}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'JACKPOT ESTIMATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jackpotStr,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bấm để xem lịch sử',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: isDark ? Colors.white38 : Colors.black38,
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget actionCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      required Color color,
    }) {
      return Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          actionCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Gợi ý số AI',
            subtitle: 'Phán đoán bằng học máy',
            color: const Color(0xFFD946EF),
            onTap: () {
              widget.onNavigateToTab(1);
            },
          ),
          const SizedBox(width: 12),
          actionCard(
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            subtitle: 'Thay đổi giao diện & ngôn ngữ',
            color: const Color(0xFF0F766E),
            onTap: () {
              widget.onNavigateToTab(2);
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 2. SETTINGS VIEW
// ----------------------------------------------------
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  String _getThemeDisplay(AppThemeMode mode, AppLocalizations localizations) {
    switch (mode) {
      case AppThemeMode.lightRed:
        return localizations.themeLightRed;
      case AppThemeMode.darkSlate:
        return localizations.themeDarkSlate;
      case AppThemeMode.goldLuxury:
        return localizations.themeGoldLuxury;
      case AppThemeMode.cyberMidnight:
        return localizations.themeCyberMidnight;
      case AppThemeMode.nordicMint:
        return localizations.themeNordicMint;
    }
  }

  void _showLanguageBottomSheet(BuildContext context, AppSettings settings, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bottom sheet grab handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  localizations.language,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(
                    localizations.langVi,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  trailing: settings.locale.languageCode == 'vi'
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settings.setLocale(const Locale('vi'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(
                    localizations.langEn,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  trailing: settings.locale.languageCode == 'en'
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settings.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeBottomSheet(BuildContext context, AppSettings settings, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeOptions = [
      {'mode': AppThemeMode.lightRed, 'icon': Icons.wb_sunny_outlined, 'name': localizations.themeLightRed},
      {'mode': AppThemeMode.darkSlate, 'icon': Icons.nightlight_round_outlined, 'name': localizations.themeDarkSlate},
      {'mode': AppThemeMode.goldLuxury, 'icon': Icons.workspace_premium_outlined, 'name': localizations.themeGoldLuxury},
      {'mode': AppThemeMode.cyberMidnight, 'icon': Icons.bolt_outlined, 'name': localizations.themeCyberMidnight},
      {'mode': AppThemeMode.nordicMint, 'icon': Icons.park_outlined, 'name': localizations.themeNordicMint},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  localizations.theme,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: themeOptions.length,
                    itemBuilder: (context, index) {
                      final option = themeOptions[index];
                      final mode = option['mode']! as AppThemeMode;
                      final isSelected = settings.themeMode == mode;

                      return ListTile(
                        leading: Icon(option['icon']! as IconData),
                        title: Text(
                          option['name']! as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          settings.setThemeMode(mode);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          // General Section
          _buildSectionHeader(theme, localizations.language),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(
                    localizations.language,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    settings.locale.languageCode == 'vi' ? 'Tiếng Việt' : 'English',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12.5),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () => _showLanguageBottomSheet(context, settings, localizations),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? const Color(0xFF222F43) : const Color(0xFFFAF9F6),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(
                    localizations.theme,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    _getThemeDisplay(settings.themeMode, localizations),
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12.5),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () => _showThemeBottomSheet(context, settings, localizations),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Update section
          _buildSectionHeader(theme, localizations.checkUpdate),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update_outlined),
              title: Text(
                localizations.checkUpdate,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              trailing: const Icon(Icons.keyboard_arrow_right),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                UpdateService.instance.checkAndShowUpdateDialog(
                  context,
                  showUpToDateFeedback: true,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Info section
          _buildSectionHeader(theme, localizations.appInfo),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                localizations.appDisclaimer,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
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
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
