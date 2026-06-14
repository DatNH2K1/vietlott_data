import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vietlott_data/services/theme/app_themes.dart';

class AppSettings extends ChangeNotifier {
  AppSettings() {
    _loadFromPrefs();
  }
  AppThemeMode _themeMode = AppThemeMode.lightRed;
  Locale _locale = const Locale('vi');

  AppThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeIndex = prefs.getInt('themeMode');
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < AppThemeMode.values.length) {
        _themeMode = AppThemeMode.values[themeIndex];
      }

      final languageCode = prefs.getString('languageCode');
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }

      notifyListeners();
    } catch (e) {
      print('Error loading settings from SharedPreferences: $e');
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('themeMode', mode.index);
      } catch (e) {
        print('Error saving theme settings: $e');
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('languageCode', locale.languageCode);
      } catch (e) {
        print('Error saving locale settings: $e');
      }
    }
  }
}

class AppSettingsProvider extends InheritedNotifier<AppSettings> {
  const AppSettingsProvider({
    required AppSettings super.notifier,
    required super.child,
    super.key,
  });

  static AppSettings of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<AppSettingsProvider>();
    assert(provider != null, 'No AppSettingsProvider found in context');
    return provider!.notifier!;
  }
}
