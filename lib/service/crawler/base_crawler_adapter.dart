import 'package:vietlott_data/models/lottery_draw_model.dart';

/// Abstract base class for all Vietlott product crawler adapters.
abstract class BaseCrawlerAdapter {
  /// Name of the product (e.g. 'power535').
  String get productName;

  /// Fetches a specific page of draw history.
  Future<List<LotteryDrawModel>> fetchPage(int pageIndex);
}
