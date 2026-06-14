import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/crawler/adapters/base_adapters.dart';
import 'package:vietlott_data/services/crawler/adapters/git_sync_adapter.dart';
import 'package:vietlott_data/services/crawler/adapters/mega645_adapter.dart';
import 'package:vietlott_data/services/crawler/adapters/power535_adapter.dart';
import 'package:vietlott_data/services/crawler/adapters/power655_adapter.dart';

export 'adapters/base_adapters.dart';
export 'adapters/mega645_adapter.dart';
export 'adapters/power535_adapter.dart';
export 'adapters/power655_adapter.dart';

/// Centralized manager for all lottery product crawler adapters.
class LotteryCrawler {
  static final Map<String, BaseCrawlerAdapter> _registry = {
    'power535': Power535Adapter(),
    'mega645': Mega645Adapter(),
    'power655': Power655Adapter(),
  };

  /// Retrieves a crawler adapter by its product name.
  static BaseCrawlerAdapter? getAdapter(String productName) {
    return _registry[productName];
  }

  /// Lists all registered product names.
  static List<String> get supportedProducts => _registry.keys.toList();
}

/// Coordinator to synchronize raw data from Git to local SQLite when local database is empty.
class SyncManager {
  SyncManager._init();
  // Singleton pattern
  static final SyncManager instance = SyncManager._init();

  final List<BaseSyncAdapter> _adapters = [
    GitSyncAdapter('power535'),
    GitSyncAdapter('mega645'),
    GitSyncAdapter('power655'),
  ];

  /// Lists all registered sync adapters.
  List<BaseSyncAdapter> get adapters => List.unmodifiable(_adapters);

  /// Synchronizes lottery draws from Git to SQLite for any registered product
  /// whose database table has 0 records (i.e. fresh install or cleared database).
  Future<void> syncIfEmpty() async {
    final lotteryRepo = LotteryRepository();

    for (final adapter in _adapters) {
      final product = adapter.productName;

      try {
        final isEmpty = await lotteryRepo.isProductEmpty(product);
        if (isEmpty) {
          print(
            'Local database for "$product" is empty. Initializing sync from Git...',
          );

          final draws = await adapter.fetchDraws();
          print(
            'Successfully fetched ${draws.length} draws for "$product" from Git.',
          );

          if (draws.isNotEmpty) {
            await lotteryRepo.insertDraws(product, draws);
            print(
              'Inserted ${draws.length} draws into local SQLite database for "$product".',
            );
          } else {
            print('No draws found for "$product" to insert.');
          }
        } else {
          print(
            'Local database for "$product" already has data. Skipping initial Git sync.',
          );
        }
      } catch (e) {
        print('Error syncing "$product" from Git to database: $e');
      }
    }
  }

  /// Crawls the latest draws for a specific product using its crawler adapter.
  /// It crawls page-by-page starting at 1 and stops when it encounters a draw ID
  /// that is already present in the local database.
  Future<void> crawlLatestData(String productName) async {
    final adapter = LotteryCrawler.getAdapter(productName);
    if (adapter == null) {
      print('No crawler adapter found for "$productName".');
      return;
    }

    final lotteryRepo = LotteryRepository();
    final latestLocalDraws = await lotteryRepo.getDraws(productName, limit: 1);
    final latestLocalId = latestLocalDraws.isNotEmpty ? latestLocalDraws.first.id : null;

    var pageIndex = 1;
    final allNewDraws = <LotteryDrawModel>[];
    var hasNewData = true;

    try {
      while (hasNewData) {
        print('Crawling page $pageIndex for "$productName"...');
        final draws = await adapter.fetchPage(pageIndex);
        if (draws.isEmpty) {
          print('No draws returned on page $pageIndex for "$productName". Stopping.');
          break;
        }

        for (final draw in draws) {
          if (latestLocalId != null) {
            final drawIdInt = int.tryParse(draw.id);
            final localIdInt = int.tryParse(latestLocalId);
            if (drawIdInt != null && localIdInt != null) {
              if (drawIdInt <= localIdInt) {
                hasNewData = false;
                break;
              }
            } else if (draw.id == latestLocalId) {
              hasNewData = false;
              break;
            }
          }
          allNewDraws.add(draw);
        }

        if (!hasNewData || draws.length < 5) {
          break;
        }
        pageIndex++;
      }

      if (allNewDraws.isNotEmpty) {
        await lotteryRepo.insertDraws(productName, allNewDraws.reversed.toList());
        print('Successfully crawled and inserted ${allNewDraws.length} new draws for "$productName".');
      } else {
        print('No new draws found for "$productName".');
      }

      // Always update last_updated so we don't query again too soon
      await lotteryRepo.updateLastUpdated(productName);
    } catch (e) {
      print('Error crawling latest data for "$productName": $e');
    }
  }
}
