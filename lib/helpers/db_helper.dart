import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model; // Alias to avoid conflict
import '../models/subscription.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nammaexpense.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN origin INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE transactions ADD COLUMN linkedGroupId TEXT');
      await db.execute('ALTER TABLE subscriptions ADD COLUMN type INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE subscriptions ADD COLUMN totalDurationDays INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE subscriptions ADD COLUMN cycleDays INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE transactions ADD COLUMN time TEXT DEFAULT '00:00'");
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN isStarred INTEGER DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Transactions Table
    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  title $textType,
  amount $doubleType,
  date $textType,
  time TEXT DEFAULT '00:00',
  categoryId $textType,
  type $intType,
  mood $intType,
  wallet $intType,
  description TEXT,
  origin $intType DEFAULT 0,
  linkedGroupId TEXT,
  isStarred INTEGER DEFAULT 0
)
    ''');

    // Subscriptions Table
    await db.execute('''
CREATE TABLE subscriptions (
  id $idType,
  title $textType,
  amount $doubleType,
  nextRenewalDate $textType,
  cycle $intType,
  autoRenew $intType,
  type $intType DEFAULT 0,
  totalDurationDays INTEGER,
  cycleDays INTEGER
)
    ''');
  }

  // --- Transaction CRUD ---

  Future<void> insertTransaction(model.Transaction txn) async {
    final db = await database;
    await db.insert(
      'transactions',
      txn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(model.Transaction txn) async {
    final db = await database;
    await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    final mapList = await db.query('transactions', orderBy: 'date DESC');

    return mapList.map((json) => model.Transaction.fromMap(json)).toList();
  }

  Future<void> toggleStar(String id, bool isStarred) async {
    final db = await database;
    await db.update(
      'transactions',
      {'isStarred': isStarred ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTransactionGroup(String groupId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'linkedGroupId = ?',
      whereArgs: [groupId],
    );
  }

  // --- Subscription CRUD ---

  Future<void> insertSubscription(Subscription sub) async {
    final db = await database;
    await db.insert(
      'subscriptions',
      sub.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subscription>> getSubscriptions() async {
    final db = await database;
    final mapList = await db.query('subscriptions', orderBy: 'nextRenewalDate ASC');

    return mapList.map((json) => Subscription.fromMap(json)).toList();
  }
  
  Future<void> deleteSubscription(String id) async {
    final db = await database;
    await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Backup & Restore ---

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('subscriptions');
    });
  }

  Future<void> insertTransactionsBatch(List<model.Transaction> txns) async {
    final db = await database;
    final batch = db.batch();
    for (var tx in txns) {
      batch.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertSubscriptionsBatch(List<Subscription> subs) async {
    final db = await database;
    final batch = db.batch();
    for (var sub in subs) {
      batch.insert(
        'subscriptions',
        sub.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
