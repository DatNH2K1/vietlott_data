import 'package:flutter/material.dart';
import 'package:vietlott_data/app/app.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppSettingsProvider(notifier: AppSettings(), child: const MyApp()));
}
