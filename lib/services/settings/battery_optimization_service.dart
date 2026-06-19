import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimizationService {
  BatteryOptimizationService._init();
  static final BatteryOptimizationService instance = BatteryOptimizationService._init();

  static const _channel = MethodChannel('com.datnh.vietlott_data/battery_optimization');
  static const _prefKeyLastPrompt = 'last_battery_optimization_prompt';

  /// Checks if the app is already ignoring battery optimization restrictions.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final isIgnoring = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return isIgnoring ?? false;
    } on PlatformException catch (e) {
      print('Failed to check battery optimization: ${e.message}');
      return true; // Gracefully fallback
    }
  }

  /// Request the user to disable battery optimization for this app.
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      print('Failed to request ignore battery optimization: ${e.message}');
    }
  }

  /// Check if the prompt dialog should be shown (at most once every 3 days).
  Future<bool> shouldPromptForBatteryOptimization() async {
    final isIgnoring = await isIgnoringBatteryOptimizations();
    if (isIgnoring) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastPromptStr = prefs.getString(_prefKeyLastPrompt);

    if (lastPromptStr == null) {
      return true;
    }

    final lastPromptTime = DateTime.tryParse(lastPromptStr);
    if (lastPromptTime == null) {
      return true;
    }

    final diff = DateTime.now().difference(lastPromptTime);
    return diff.inDays >= 3;
  }

  /// Marks that a prompt was shown to update the throttle timer.
  Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastPrompt, DateTime.now().toIso8601String());
  }
}
