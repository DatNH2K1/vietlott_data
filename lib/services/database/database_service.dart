import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service to manage local SQLite database storage for lottery draw data.
class DatabaseService {
  DatabaseService._init();
  // Private constructor and Singleton instance
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  /// Retrieves the active database connection, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vietlott.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database connection (enabling foreign keys support).
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Create the lottery_products table (with a nullable jackpot column and last_updated)
    await db.execute('''
      CREATE TABLE lottery_products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        jackpot INTEGER,
        last_updated TEXT
      )
    ''');

    // 2. Create the primary table for draws metadata (product_id references lottery_products.id)
    await db.execute('''
      CREATE TABLE lottery_draws (
        product_id TEXT NOT NULL,
        draw_id TEXT NOT NULL,
        draw_date TEXT NOT NULL,
        PRIMARY KEY (product_id, draw_id),
        FOREIGN KEY (product_id) REFERENCES lottery_products (id) ON DELETE CASCADE
      )
    ''');

    // Create index on product_id and date to speed up queries
    await db.execute('''
      CREATE INDEX idx_lottery_draws_product_date 
      ON lottery_draws (product_id, draw_date DESC)
    ''');

    // 3. Create the child table for individual draw numbers, referencing lottery_draws (product_id, draw_id)
    await db.execute('''
      CREATE TABLE draw_numbers (
        product_id TEXT NOT NULL,
        draw_id TEXT NOT NULL,
        number INTEGER NOT NULL,
        type TEXT NOT NULL,
        sequence_index INTEGER NOT NULL,
        PRIMARY KEY (product_id, draw_id, type, sequence_index),
        FOREIGN KEY (product_id, draw_id) REFERENCES lottery_draws (product_id, draw_id) ON DELETE CASCADE
      )
    ''');
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
