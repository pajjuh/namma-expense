import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class StarredExpensesScreen extends StatefulWidget {
  const StarredExpensesScreen({super.key});

  @override
  State<StarredExpensesScreen> createState() => _StarredExpensesScreenState();
}

class _StarredExpensesScreenState extends State<StarredExpensesScreen> {
  String _sortBy = 'date'; // 'date', 'amount'
  String _filterType = 'all'; // 'all', 'expense', 'income'
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;

    List<Transaction> starred = expenseProvider.starredTransactions;

    // Apply type filter
    if (_filterType == 'expense') {
      starred = starred.where((t) => t.type == TransactionType.expense).toList();
    } else if (_filterType == 'income') {
      starred = starred.where((t) => t.type == TransactionType.income).toList();
    }

    // Apply category filter
    if (_filterCategoryId != null) {
      starred = starred.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    // Apply sort
    if (_sortBy == 'amount') {
      starred.sort((a, b) => b.amount.compareTo(a.amount));
    } else {
      starred.sort((a, b) => b.date.compareTo(a.date));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.02),
            const Text('Starred Expenses'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, categories),
          ),
        ],
      ),
      body: starred.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: screenWidth * 0.2, color: Colors.grey.shade300),
                  SizedBox(height: screenWidth * 0.04),
                  Text(
                    'No starred expenses yet',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    'Swipe right on any transaction to star it',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary bar
                Container(
                  margin: EdgeInsets.all(screenWidth * 0.04),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${starred.length}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          Text('Starred', style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$currency${starred.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text('Expenses', style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$currency${starred.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text('Income', style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active filters chips
                if (_filterType != 'all' || _filterCategoryId != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Row(
                      children: [
                        if (_filterType != 'all')
                          Padding(
                            padding: EdgeInsets.only(right: screenWidth * 0.02),
                            child: Chip(
                              label: Text(_filterType == 'expense' ? 'Expenses' : 'Income'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _filterType = 'all'),
                            ),
                          ),
                        if (_filterCategoryId != null)
                          Chip(
                            label: Text(
                              categories.firstWhere(
                                (c) => c.id == _filterCategoryId,
                                orElse: () => Category(id: '', name: _filterCategoryId!, icon: Icons.category, color: Colors.grey),
                              ).name,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => _filterCategoryId = null),
                          ),
                      ],
                    ),
                  ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                    itemCount: starred.length,
                    itemBuilder: (ctx, i) {
                      final tx = starred[i];
                      Category cat;
                      try {
                        cat = categories.firstWhere((c) => c.id == tx.categoryId);
                      } catch (e) {
                        cat = Category(id: tx.categoryId, name: tx.categoryId, icon: Icons.category, color: Colors.grey);
                      }
                      final isExpense = tx.type == TransactionType.expense;

                      return Dismissible(
                        key: Key(tx.id),
                        background: Container(
                          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: screenWidth * 0.04),
                          child: const Icon(Icons.star_border, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: screenWidth * 0.04),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Unstar
                            expenseProvider.toggleStarTransaction(tx.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from Starred ⭐'), duration: Duration(seconds: 1)),
                            );
                            return false;
                          } else {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Transaction?'),
                                content: Text('Delete "${tx.title}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              expenseProvider.deleteTransaction(tx.id);
                            }
                            return false;
                          }
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 3),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddTransactionScreen(existingTransaction: tx)),
                              );
                            },
                            leading: CircleAvatar(
                              radius: screenWidth * 0.05,
                              backgroundColor: cat.color.withOpacity(0.15),
                              child: Icon(cat.icon, color: cat.color, size: screenWidth * 0.05),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: screenWidth * 0.04),
                                SizedBox(width: screenWidth * 0.015),
                                Expanded(
                                  child: Text(
                                    tx.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: screenWidth * 0.038),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${DateFormat.MMMd().format(tx.date)}, ${tx.formattedTime} • ${cat.name}',
                              style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey),
                            ),
                            trailing: Text(
                              '${isExpense ? '-' : '+'}$currency${tx.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isExpense ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showFilterSheet(BuildContext context, List<Category> categories) {
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetMaxHeight = MediaQuery.of(context).size.height * 0.6;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sheetMaxHeight),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.05,
                  screenWidth * 0.04,
                  screenWidth * 0.05,
                  MediaQuery.of(ctx).viewInsets.bottom + screenWidth * 0.04,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Text('Filter & Sort', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
                    SizedBox(height: screenWidth * 0.03),

                    // Sort
                    Text('Sort By', style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w600)),
                    SizedBox(height: screenWidth * 0.015),
                    Wrap(
                      spacing: screenWidth * 0.02,
                      children: [
                        ChoiceChip(
                          label: const Text('Date'),
                          selected: _sortBy == 'date',
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _sortBy = 'date');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Amount'),
                          selected: _sortBy == 'amount',
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _sortBy = 'amount');
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.03),

                    // Type filter
                    Text('Type', style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w600)),
                    SizedBox(height: screenWidth * 0.015),
                    Wrap(
                      spacing: screenWidth * 0.02,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _filterType == 'all',
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _filterType = 'all');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: _filterType == 'expense',
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _filterType = 'expense');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: _filterType == 'income',
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _filterType = 'income');
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.03),

                    // Category filter
                    Text('Category', style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w600)),
                    SizedBox(height: screenWidth * 0.015),
                    Wrap(
                      spacing: screenWidth * 0.02,
                      runSpacing: screenWidth * 0.015,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _filterCategoryId == null,
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _filterCategoryId = null);
                          },
                        ),
                        ...categories.map((cat) => ChoiceChip(
                          label: Text(cat.name),
                          selected: _filterCategoryId == cat.id,
                          avatar: Icon(cat.icon, size: 14, color: cat.color),
                          onSelected: (_) {
                            setSheetState(() {});
                            setState(() => _filterCategoryId = cat.id);
                          },
                        )),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.04),

                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _sortBy = 'date';
                            _filterType = 'all';
                            _filterCategoryId = null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
