import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/database/database_service.dart';

void main() {
  // Initialize sqflite FFI for local host execution during unit testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService and LotteryRepository Tests', () {
    final dbService = DatabaseService.instance;
    final lotteryRepo = LotteryRepository();

    setUp(() async {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'vietlott.db');
      await deleteDatabase(path);
    });

    tearDown(() async {
      // Close database connection after each test
      await dbService.close();
    });

    test(
      'Insert and query lottery draws with normalized split tables via Repository',
      () async {
        const product = 'test_power';

        // Verify empty database
        final initiallyEmpty = await lotteryRepo.isProductEmpty(product);
        expect(initiallyEmpty, isTrue);

        final testDraws = [
          LotteryDrawModel(
            id: '00001',
            date: '2026-06-10',
            regular: [1, 2, 3, 4, 5],
            special: [6],
          ),
          LotteryDrawModel(
            id: '00002',
            date: '2026-06-12',
            regular: [10, 11, 12, 13, 14],
            special: [15, 16],
          ),
        ];

        // Batch insert into Database (this should also auto-insert product into lottery_products)
        await lotteryRepo.insertDraws(product, testDraws);

        // Verify product table was populated with null jackpot initially
        final db = await dbService.database;
        final productResultBefore = await db.query(
          'lottery_products',
          where: 'id = ?',
          whereArgs: [product],
        );
        expect(productResultBefore.length, equals(1));
        expect(productResultBefore.first['name'], equals('TEST_POWER'));
        expect(productResultBefore.first['jackpot'], isNull);
        expect(productResultBefore.first['last_updated'], isNotNull);

        // Save initial last updated time
        final initialLastUpdated =
            productResultBefore.first['last_updated'] as String?;

        // Small delay to ensure timestamp would change if updated
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Update jackpot
        await lotteryRepo.updateJackpot(product, 30000000000);

        // Verify updated value
        final productResultAfter = await db.query(
          'lottery_products',
          where: 'id = ?',
          whereArgs: [product],
        );
        expect(productResultAfter.first['jackpot'], equals(30000000000));
        expect(productResultAfter.first['last_updated'], isNotNull);
        expect(
          productResultAfter.first['last_updated'],
          isNot(equals(initialLastUpdated)),
        );

        // Verify no longer empty
        final nowEmpty = await lotteryRepo.isProductEmpty(product);
        expect(nowEmpty, isFalse);

        // Retrieve all draws from database
        final retrieved = await lotteryRepo.getDraws(product);

        expect(retrieved.length, equals(2));

        // Assert descending date order sorting (00002 should come first since 2026-06-12 > 2026-06-10)
        final firstDraw = retrieved[0];
        expect(firstDraw.id, equals('00002'));
        expect(firstDraw.date, equals('2026-06-12'));
        expect(firstDraw.regular, equals([10, 11, 12, 13, 14]));
        expect(firstDraw.special, equals([15, 16]));

        final secondDraw = retrieved[1];
        expect(secondDraw.id, equals('00001'));
        expect(secondDraw.date, equals('2026-06-10'));
        expect(secondDraw.regular, equals([1, 2, 3, 4, 5]));
        expect(secondDraw.special, equals([6]));
      },
    );
  });
}
