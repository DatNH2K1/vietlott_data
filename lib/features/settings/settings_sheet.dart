import 'package:flutter/material.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';
import 'package:vietlott_data/services/theme/app_themes.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsProvider.of(context);
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.settings,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),

          // Language Selection
          Row(
            children: [
              Icon(
                Icons.language_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.language,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOptionButton(
                context,
                label: localizations.langVi,
                isSelected: settings.locale.languageCode == 'vi',
                onTap: () => settings.setLocale(const Locale('vi')),
              ),
              const SizedBox(width: 12),
              _buildOptionButton(
                context,
                label: localizations.langEn,
                isSelected: settings.locale.languageCode == 'en',
                onTap: () => settings.setLocale(const Locale('en')),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Theme Selection
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.theme,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOptionButton(
                context,
                label: localizations.themeLightRed,
                isSelected: settings.themeMode == AppThemeMode.lightRed,
                onTap: () => settings.setThemeMode(AppThemeMode.lightRed),
              ),
              _buildOptionButton(
                context,
                label: localizations.themeDarkSlate,
                isSelected: settings.themeMode == AppThemeMode.darkSlate,
                onTap: () => settings.setThemeMode(AppThemeMode.darkSlate),
              ),
              _buildOptionButton(
                context,
                label: localizations.themeGoldLuxury,
                isSelected: settings.themeMode == AppThemeMode.goldLuxury,
                onTap: () => settings.setThemeMode(AppThemeMode.goldLuxury),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
