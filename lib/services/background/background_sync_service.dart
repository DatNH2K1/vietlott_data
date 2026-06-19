import 'package:flutter/widgets.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/crawler/crawler_service.dart';
import 'package:workmanager/workmanager.dart';

const String backgroundSyncTaskName = 'com.datnh.vietlott_data.background_sync_task';
const String backgroundSyncUniqueName = 'backgroundSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('BackgroundSyncService: Background task "$task" started.');
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      final lotteryRepo = LotteryRepository();
      SyncManager.instance.init(lotteryRepo);

      // 1. Sync jackpots
      print('BackgroundSyncService: Syncing jackpots...');
      await SyncManager.instance.syncJackpots();

      // 2. Sync all supported products
      for (final product in LotteryCrawler.supportedProducts) {
        print('BackgroundSyncService: Crawling latest data for $product...');
        await SyncManager.instance.crawlLatestData(product);
      }

      print('BackgroundSyncService: Background task completed successfully.');
      return true;
    } catch (e, stackTrace) {
      print('BackgroundSyncService: Error during background task execution: $e');
      print(stackTrace);
      return false;
    }
  });
}

class BackgroundSyncService {
  BackgroundSyncService._init();
  static final BackgroundSyncService instance = BackgroundSyncService._init();

  /// Initializes the Workmanager with the callback dispatcher.
  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  /// Registers the periodic 6-hour background sync job.
  Future<void> register6HourPeriodicTask() async {
    print('BackgroundSyncService: Registering 6-hour periodic task...');
    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskName,
      backgroundSyncUniqueName,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Cancels the periodic background sync job.
  Future<void> cancelPeriodicTask() async {
    print('BackgroundSyncService: Cancelling periodic task...');
    await Workmanager().cancelByUniqueName(backgroundSyncTaskName);
  }
}
