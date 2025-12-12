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
      version: 1,
      onCreate: _createDB,
    );
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
  categoryId $textType,
  type $intType,
  mood $intType,
  wallet $intType,
  description TEXT
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
  autoRenew $intType
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

  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    final mapList = await db.query('transactions', orderBy: 'date DESC');

    return mapList.map((json) => model.Transaction.fromMap(json)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
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
}
