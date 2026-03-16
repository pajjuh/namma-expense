import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../helpers/db_helper.dart';
import '../helpers/constants.dart';

class ExpenseProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  final DBHelper _dbHelper = DBHelper();

  List<Transaction> get transactions => _transactions;

  List<Transaction> get recentTransactions {
    return _transactions.take(10).toList();
  }

  double get totalBalance {
    double income = 0.0;
    double expense = 0.0;
    for (var txn in _transactions) {
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else {
        expense += txn.amount;
      }
    }
    return income - expense;
  }

  double get totalIncome {
    return _transactions
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> fetchTransactions() async {
    _transactions = await _dbHelper.getTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction txn) async {
    await _dbHelper.insertTransaction(txn);
    await fetchTransactions(); // Refresh list
  }

  Future<void> updateTransaction(Transaction txn) async {
    await _dbHelper.updateTransaction(txn);
    await fetchTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _dbHelper.deleteTransaction(id);
    await fetchTransactions();
  }

  // --- Statistics Logic ---
  
  // Get expense amount by Category ID
  Map<String, double> get categorySpending {
    Map<String, double> stats = {};
    for (var txn in _transactions.where((t) => t.type == TransactionType.expense)) {
      if (stats.containsKey(txn.categoryId)) {
        stats[txn.categoryId] = stats[txn.categoryId]! + txn.amount;
      } else {
        stats[txn.categoryId] = txn.amount;
      }
    }
    return stats;
  }

  // Get spending for Heatmap (Date -> Amount)
  Map<DateTime, int> get heathMapData {
    Map<DateTime, int> data = {};
    for (var txn in _transactions.where((t) => t.type == TransactionType.expense)) {
      final dateKey = DateTime(txn.date.year, txn.date.month, txn.date.day);
      if (data.containsKey(dateKey)) {
        data[dateKey] = data[dateKey]! + txn.amount.toInt();
      } else {
        data[dateKey] = txn.amount.toInt();
      }
    }
    return data;
  }
}
