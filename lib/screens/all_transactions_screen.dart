import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../models/transaction.dart' as model;
import 'add_transaction_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  // Filters
  TransactionType? _typeFilter;
  String? _categoryFilter;

  // Track which months are expanded (by "yyyy-MM" key)
  final Set<String> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand the current month
    final now = DateTime.now();
    _expandedMonths.add('${now.year}-${now.month.toString().padLeft(2, '0')}');
  }

  /// Groups transactions by month key "yyyy-MM", sorted most recent first
  Map<String, List<model.Transaction>> _groupByMonth(List<model.Transaction> txns) {
    final Map<String, List<model.Transaction>> grouped = {};
    for (final tx in txns) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }
    // Sort keys descending (most recent month first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      return 'This Month — ${DateFormat.MMMM().format(date)} ${date.year}';
    }
    return '${DateFormat.MMMM().format(date)} ${date.year}';
  }

  double _monthTotal(List<model.Transaction> txns, TransactionType type) {
    return txns
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = Provider.of<ExpenseProvider>(context).transactions;
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Apply filters
    var filteredTxns = allTxns.where((tx) {
      if (_typeFilter != null && tx.type != _typeFilter) return false;
      if (_categoryFilter != null && tx.categoryId != _categoryFilter) return false;
      return true;
    }).toList();

    final grouped = _groupByMonth(filteredTxns);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          if (grouped.length > 1)
            IconButton(
              icon: const Icon(Icons.unfold_more),
              tooltip: 'Expand All',
              onPressed: () => setState(() => _expandedMonths.addAll(grouped.keys)),
            ),
          if (_expandedMonths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.unfold_less),
              tooltip: 'Collapse All',
              onPressed: () => setState(() => _expandedMonths.clear()),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, categories),
          ),
        ],
      ),
      body: filteredTxns.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: screenWidth * 0.18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    _typeFilter != null || _categoryFilter != null
                        ? 'No transactions match your filters.'
                        : 'No transactions yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.03,
              ),
              itemCount: grouped.length,
              itemBuilder: (ctx, i) {
                final monthKey = grouped.keys.elementAt(i);
                final monthTxns = grouped[monthKey]!;
                final isExpanded = _expandedMonths.contains(monthKey);
                final monthExpense = _monthTotal(monthTxns, TransactionType.expense);
                final monthIncome = _monthTotal(monthTxns, TransactionType.income);

                return Card(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Month Header (tap to expand/collapse)
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedMonths.remove(monthKey);
                            } else {
                              _expandedMonths.add(monthKey);
                            }
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.015,
                          ),
                          child: Row(
                            children: [
                              // Month icon
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  size: screenWidth * 0.05,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              // Month name + summary
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _monthLabel(monthKey),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    SizedBox(height: screenHeight * 0.004),
                                    Row(
                                      children: [
                                        Text(
                                          '${monthTxns.length} transactions',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                        ),
                                        SizedBox(width: screenWidth * 0.03),
                                        if (monthExpense > 0)
                                          Text(
                                            '-$currency${monthExpense.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (monthExpense > 0 && monthIncome > 0)
                                          Text(' • ', style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.03)),
                                        if (monthIncome > 0)
                                          Text(
                                            '+$currency${monthIncome.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Expand/collapse icon
                              AnimatedRotation(
                                turns: isExpanded ? 0.125 : 0, // 45 degrees for the + to become x-ish
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isExpanded ? Icons.remove : Icons.add,
                                  size: screenWidth * 0.06,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded transactions list
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: [
                            const Divider(height: 1),
                            ...monthTxns.map((tx) {
                              Category cat;
                              try {
                                cat = categories.firstWhere((c) => c.id == tx.categoryId);
                              } catch (e) {
                                cat = Category(
                                  id: tx.categoryId,
                                  name: tx.categoryId,
                                  icon: Icons.category,
                                  color: Colors.grey,
                                );
                              }
                              final isExpense = tx.type == TransactionType.expense;

                              return Dismissible(
                                key: Key(tx.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: screenWidth * 0.04),
                                  child: Icon(Icons.delete, color: Colors.white, size: screenWidth * 0.06),
                                ),
                                confirmDismiss: (_) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Transaction'),
                                      content: Text('Delete "${tx.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) {
                                  Provider.of<ExpenseProvider>(context, listen: false)
                                      .deleteTransaction(tx.id);
                                },
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(existingTransaction: tx),
                                      ),
                                    );
                                  },
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: screenWidth * 0.045,
                                    backgroundColor: cat.color.withOpacity(0.15),
                                    child: Icon(cat.icon, color: cat.color, size: screenWidth * 0.045),
                                  ),
                                  title: Text(
                                    tx.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: screenWidth * 0.037),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat.MMMd().format(tx.date)} • ${cat.name}',
                                    style: TextStyle(fontSize: screenWidth * 0.03, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey),
                                  ),
                                  trailing: Text(
                                    '${isExpense ? '-' : '+'}$currency${tx.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isExpense ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.036,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        crossFadeState:
                            isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showFilterSheet(BuildContext context, List<Category> categories) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filter Transactions', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: screenHeight * 0.02),

                  // Type Filter
                  Text('Type', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: screenHeight * 0.01),
                  Wrap(
                    spacing: screenWidth * 0.02,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _typeFilter == null,
                        onSelected: (_) {
                          setState(() => _typeFilter = null);
                          Navigator.pop(context);
                        },
                      ),
                      FilterChip(
                        label: const Text('Expense'),
                        selected: _typeFilter == TransactionType.expense,
                        onSelected: (_) {
                          setState(() => _typeFilter = TransactionType.expense);
                          Navigator.pop(context);
                        },
                      ),
                      FilterChip(
                        label: const Text('Income'),
                        selected: _typeFilter == TransactionType.income,
                        onSelected: (_) {
                          setState(() => _typeFilter = TransactionType.income);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Category Filter
                  Text('Category', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: screenHeight * 0.01),
                  Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: screenHeight * 0.01,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _categoryFilter == null,
                        onSelected: (_) {
                          setState(() => _categoryFilter = null);
                          Navigator.pop(context);
                        },
                      ),
                      ...categories.map((cat) => FilterChip(
                            label: Text(cat.name),
                            avatar: Icon(cat.icon, size: screenWidth * 0.04),
                            selected: _categoryFilter == cat.id,
                            onSelected: (_) {
                              setState(() => _categoryFilter = cat.id);
                              Navigator.pop(context);
                            },
                          )),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
