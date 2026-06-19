import 'package:flutter/material.dart';
import 'package:vietlott_data/app/app.dart';
import 'package:vietlott_data/services/background/background_sync_service.dart';
import 'package:vietlott_data/services/notification/notification_service.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await BackgroundSyncService.instance.init();
  runApp(AppSettingsProvider(notifier: AppSettings(), child: const MyApp()));
}
