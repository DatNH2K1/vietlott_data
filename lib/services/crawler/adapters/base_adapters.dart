import 'package:vietlott_data/models/lottery_draw_model.dart';

/// Abstract base class for all Vietlott product crawler adapters.
abstract class BaseCrawlerAdapter {
  /// Name of the product (e.g. 'power535').
  String get productName;

  /// Fetches a specific page of draw history.
  Future<List<LotteryDrawModel>> fetchPage(int pageIndex);
}

/// Interface representing a Git sync adapter for a specific lottery product.
abstract class BaseSyncAdapter {
  /// Unique identifier/name of the product (e.g. 'power535').
  String get productName;

  /// Fetches draw data from its Git source (e.g., raw JSONL file) and parses it.
  Future<List<LotteryDrawModel>> fetchDraws();
}
