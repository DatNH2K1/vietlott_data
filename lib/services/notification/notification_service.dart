import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vietlott_data/services/crawler/crawler_service.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';

class NotificationService {
  NotificationService._init();
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Initializes the local notification plugin.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings: initSettings);

    // Request permissions for Android 13+
    await requestPermission();
  }

  /// Explicitly requests POST_NOTIFICATIONS permission for Android 13+ devices.
  Future<void> requestPermission() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  /// Processes and checks jackpot alerts for a given product and jackpot value.
  Future<void> processJackpotAlerts({
    required String product,
    required int jackpot,
    required String drawId,
  }) async {
    final adapter = LotteryCrawler.getAdapter(product);
    if (adapter == null) return;

    if (adapter.shouldAlertJackpot(jackpot)) {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'jackpot_alert_${product}_$drawId';

      // Check if we have already alerted for this specific draw
      final alreadyAlerted = prefs.getBool(prefKey) ?? false;
      if (!alreadyAlerted) {
        final localeCode = await AppSettings.getSavedLanguageCode();
        final localizations = AppLocalizations(Locale(localeCode));
        await localizations.load();

        final title = localizations.translate(adapter.jackpotAlertTitleKey);
        final rawBody = localizations.translate(adapter.jackpotAlertBodyKey);
        final billionSuffix = localizations.translate('billionSuffix');

        final displayJackpot = BaseCrawlerAdapter.formatJackpotValue(jackpot, billionSuffix);
        final body = rawBody
            .replaceAll('{jackpot}', displayJackpot)
            .replaceAll('{drawId}', drawId);

        final channelName = localizations.translate('notificationChannelName');
        final channelDesc = localizations.translate('notificationChannelDesc');

        final androidDetails = AndroidNotificationDetails(
          'jackpot_alerts_channel',
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.high,
        );
        final platformDetails = NotificationDetails(android: androidDetails);

          // Use unique ID based on product hash or static incremental IDs
          final notificationId = product.hashCode + drawId.hashCode;

          print('NotificationService: Triggering notification for $product (Jackpot: $jackpot, Draw: $drawId)...');
          await _notifications.show(
            id: notificationId,
            title: title,
            body: body,
            notificationDetails: platformDetails,
          );

          // Mark as alerted to prevent spam
          await prefs.setBool(prefKey, true);
        } else {
          print('NotificationService: Already alerted for $product draw #$drawId. Skipping.');
        }
      }
  }
}
