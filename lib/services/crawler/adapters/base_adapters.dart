import 'package:vietlott_data/models/lottery_draw_model.dart';

/// Abstract base class for all Vietlott product crawler adapters.
abstract class BaseCrawlerAdapter {
  /// Name of the product (e.g. 'power535').
  String get productName;

  /// Fetches a specific page of draw history.
  Future<List<LotteryDrawModel>> fetchPage(int pageIndex);

  /// Fetches the latest jackpot value from the Vietlott homepage.
  Future<int?> fetchJackpot();

  /// Determines whether the jackpot value should trigger a notification.
  bool shouldAlertJackpot(int jackpot) => false;

  /// Gets the notification title translation key.
  String get jackpotAlertTitleKey => '';

  /// Gets the notification body translation key.
  String get jackpotAlertBodyKey => '';

  /// Helper to format raw jackpot integers into readable Billions VNĐ.
  static String formatJackpotValue(int val, String billionSuffix) {
    if (val >= 1000000000) {
      final billions = val / 1000000000;
      return '${billions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} $billionSuffix';
    }
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

/// Interface representing a Git sync adapter for a specific lottery product.
abstract class BaseSyncAdapter {
  /// Unique identifier/name of the product (e.g. 'power535').
  String get productName;

  /// Fetches draw data from its Git source (e.g., raw JSONL file) and parses it.
  Future<List<LotteryDrawModel>> fetchDraws();
}
