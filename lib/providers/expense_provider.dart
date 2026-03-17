import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/transaction.dart';
import '../helpers/db_helper.dart';
import '../helpers/constants.dart';

enum DashboardTimeFilter { day, week, month, lifetime }

class ExpenseProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  final DBHelper _dbHelper = DBHelper();

  DashboardTimeFilter _dashboardFilter = DashboardTimeFilter.month;
  final String _appGroupId = 'NammaWidgetProvider';

  DashboardTimeFilter get dashboardFilter => _dashboardFilter;

  void setDashboardFilter(DashboardTimeFilter filter) {
    _dashboardFilter = filter;
    _updateWidget();
    notifyListeners();
  }

  List<Transaction> get _effectiveTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _transactions.where((txn) {
      final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);
      return !txnDate.isAfter(today);
    }).toList();
  }

  List<Transaction> get transactions => _effectiveTransactions;

  List<Transaction> get recentTransactions {
    return _effectiveTransactions.take(10).toList();
  }

  // --- Filtered Dashboard Logic ---
  
  List<Transaction> get _filteredTransactions {
    if (_dashboardFilter == DashboardTimeFilter.lifetime) return _effectiveTransactions;
    
    final now = DateTime.now();
    return _effectiveTransactions.where((txn) {
      if (_dashboardFilter == DashboardTimeFilter.day) {
        return txn.date.year == now.year && txn.date.month == now.month && txn.date.day == now.day;
      } else if (_dashboardFilter == DashboardTimeFilter.week) {
        // Simple 7 days window
        final diff = now.difference(txn.date).inDays;
        return diff >= 0 && diff < 7;
      } else if (_dashboardFilter == DashboardTimeFilter.month) {
        return txn.date.year == now.year && txn.date.month == now.month;
      }
      return true;
    }).toList();
  }

  double get filteredBalance {
    double income = 0.0;
    double expense = 0.0;
    for (var txn in _filteredTransactions) {
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else {
        expense += txn.amount;
      }
    }
    return income - expense;
  }

  double get filteredIncome {
    return _filteredTransactions
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get filteredExpense {
    return _filteredTransactions
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- Lifetime Totals ---

  double get totalBalance {
    double income = 0.0;
    double expense = 0.0;
    for (var txn in _effectiveTransactions) {
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else {
        expense += txn.amount;
      }
    }
    return income - expense;
  }

  double get totalIncome {
    return _effectiveTransactions
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _effectiveTransactions
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> fetchTransactions() async {
    _transactions = await _dbHelper.getTransactions();
    _updateWidget();
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

  Future<void> deleteTransactionGroup(String groupId) async {
    await _dbHelper.deleteTransactionGroup(groupId);
    await fetchTransactions();
  }

  // --- Statistics Logic ---
  
  // Get expense amount by Category ID
  Map<String, double> get categorySpending {
    Map<String, double> stats = {};
    for (var txn in _effectiveTransactions.where((t) => t.type == TransactionType.expense)) {
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
    for (var txn in _effectiveTransactions.where((t) => t.type == TransactionType.expense)) {
      final dateKey = DateTime(txn.date.year, txn.date.month, txn.date.day);
      if (data.containsKey(dateKey)) {
        data[dateKey] = data[dateKey]! + txn.amount.toInt();
      } else {
        data[dateKey] = txn.amount.toInt();
      }
    }
    return data;
  }

  // --- Widget Integration ---

  Future<void> _updateWidget() async {
    await HomeWidget.saveWidgetData<String>('filtered_balance', filteredBalance.toStringAsFixed(0));
    await HomeWidget.saveWidgetData<String>('filtered_income', filteredIncome.toStringAsFixed(0));
    await HomeWidget.saveWidgetData<String>('filtered_expense', filteredExpense.toStringAsFixed(0));
    
    // Convert filter enum to a display string
    String filterLabel = 'Month';
    if (_dashboardFilter == DashboardTimeFilter.day) filterLabel = 'Today';
    if (_dashboardFilter == DashboardTimeFilter.week) filterLabel = 'Week';
    if (_dashboardFilter == DashboardTimeFilter.month) filterLabel = 'Month';
    if (_dashboardFilter == DashboardTimeFilter.lifetime) filterLabel = 'Lifetime';
    await HomeWidget.saveWidgetData<String>('current_filter', filterLabel);

    await HomeWidget.updateWidget(
      name: 'NammaWidgetProvider',
      androidName: 'NammaWidgetProvider',
      iOSName: 'NammaWidgetProvider',
    );
  }
}
