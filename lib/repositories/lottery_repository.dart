import 'package:sqflite/sqflite.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/services/database/database_service.dart';

/// Repository that handles data CRUD operations and raw SQL queries for lottery data.
class LotteryRepository {
  LotteryRepository({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService.instance;

  final DatabaseService _dbService;

  /// Checks if a given product has any stored draw history in the database.
  Future<bool> isProductEmpty(String productName) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lottery_draws WHERE product_id = ? LIMIT 1',
      [productName],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count == 0;
  }

  /// Batch inserts a list of draws and their numbers for a specific product in chunks.
  Future<void> insertDraws(
    String productName,
    List<LotteryDrawModel> draws,
  ) async {
    if (draws.isEmpty) return;

    final db = await _dbService.database;

    // Ensure the product exists in the lottery_products table first (retains existing jackpot value if already inserted)
    await db.insert('lottery_products', {
      'id': productName,
      'name': _getDisplayName(productName),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Update last_updated timestamp
    final nowString = DateTime.now().toIso8601String();
    await db.update(
      'lottery_products',
      {'last_updated': nowString},
      where: 'id = ?',
      whereArgs: [productName],
    );

    // Split inserts into chunked transactions of 500 draws to optimize transaction overhead and memory usage
    const chunkSize = 500;
    for (var i = 0; i < draws.length; i += chunkSize) {
      final chunk = draws.sublist(
        i,
        i + chunkSize > draws.length ? draws.length : i + chunkSize,
      );

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final draw in chunk) {
          // Insert draw metadata (will trigger CASCADE delete on child draw_numbers if row is replaced)
          batch.insert('lottery_draws', {
            'product_id': productName,
            'draw_id': draw.id,
            'draw_date': draw.date,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Insert regular numbers
          for (var j = 0; j < draw.regular.length; j++) {
            batch.insert('draw_numbers', {
              'product_id': productName,
              'draw_id': draw.id,
              'number': draw.regular[j],
              'type': 'regular',
              'sequence_index': j,
            });
          }

          // Insert special numbers
          for (var j = 0; j < draw.special.length; j++) {
            batch.insert('draw_numbers', {
              'product_id': productName,
              'draw_id': draw.id,
              'number': draw.special[j],
              'type': 'special',
              'sequence_index': j,
            });
          }
        }
        await batch.commit(noResult: true);
      });
    }
  }

  /// Updates the jackpot value for a specific product.
  Future<void> updateJackpot(String productName, int jackpot) async {
    final db = await _dbService.database;
    final nowString = DateTime.now().toIso8601String();
    await db.update(
      'lottery_products',
      {'jackpot': jackpot, 'last_updated': nowString},
      where: 'id = ?',
      whereArgs: [productName],
    );
  }

  /// Retrieves a paginated list of draws and their numbers for a specific product, ordered by date descending.
  Future<List<LotteryDrawModel>> getDraws(
    String productName, {
    int? limit,
    int? offset,
  }) async {
    final db = await _dbService.database;

    // Fetch draws metadata with limit and offset
    final drawMaps = await db.query(
      'lottery_draws',
      where: 'product_id = ?',
      whereArgs: [productName],
      orderBy: 'draw_date DESC',
      limit: limit,
      offset: offset,
    );

    if (drawMaps.isEmpty) return [];

    final drawIds = drawMaps.map((map) => map['draw_id']! as String).toList();
    final placeholders = List.filled(drawIds.length, '?').join(', ');

    // Fetch only numbers for these drawIds ordered by index to preserve draw order
    final numberMaps = await db.query(
      'draw_numbers',
      where: 'product_id = ? AND draw_id IN ($placeholders)',
      whereArgs: [productName, ...drawIds],
      orderBy: 'sequence_index ASC',
    );

    // Group numbers by draw_id
    final regularMap = <String, List<int>>{};
    final specialMap = <String, List<int>>{};

    for (final numMap in numberMaps) {
      final drawId = numMap['draw_id']! as String;
      final number = numMap['number']! as int;
      final type = numMap['type']! as String;

      if (type == 'regular') {
        regularMap.putIfAbsent(drawId, () => []).add(number);
      } else if (type == 'special') {
        specialMap.putIfAbsent(drawId, () => []).add(number);
      }
    }

    return drawMaps.map((map) {
      final drawId = map['draw_id']! as String;
      return LotteryDrawModel(
        id: drawId,
        date: map['draw_date']! as String,
        regular: regularMap[drawId] ?? [],
        special: specialMap[drawId] ?? [],
      );
    }).toList();
  }

  /// Retrieves the last updated timestamp for a product.
  Future<DateTime?> getLastUpdated(String productName) async {
    final db = await _dbService.database;
    final result = await db.query(
      'lottery_products',
      columns: ['last_updated'],
      where: 'id = ?',
      whereArgs: [productName],
    );
    if (result.isEmpty) return null;
    final lastUpdatedStr = result.first['last_updated'] as String?;
    if (lastUpdatedStr == null) return null;
    return DateTime.tryParse(lastUpdatedStr);
  }

  /// Updates the last updated timestamp to current time for a product.
  Future<void> updateLastUpdated(String productName) async {
    final db = await _dbService.database;
    await db.insert('lottery_products', {
      'id': productName,
      'name': _getDisplayName(productName),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final nowString = DateTime.now().toIso8601String();
    await db.update(
      'lottery_products',
      {'last_updated': nowString},
      where: 'id = ?',
      whereArgs: [productName],
    );
  }

  /// Helper to get a human-readable display name for a lottery product.
  String _getDisplayName(String product) {
    return product.toUpperCase();
  }
}
