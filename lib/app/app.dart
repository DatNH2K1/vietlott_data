import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vietlott_data/features/home/home_page.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';
import 'package:vietlott_data/services/theme/app_themes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsProvider.of(context);

    return MaterialApp(
      title: 'Vietlott Analytics',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.getTheme(settings.themeMode),
      locale: settings.locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DrawHistoryPage(),
    );
  }
}
