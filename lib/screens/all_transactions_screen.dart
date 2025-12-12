import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../models/transaction.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  DateTimeRange? _dateRange;
  String? _selectedCategory;
  TransactionType? _selectedType;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categories = Provider.of<UserProvider>(context, listen: false).categories;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, 
                right: 16, 
                top: 16
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filter Transactions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  
                  // Date Filter
                  ListTile(
                    title: const Text('Date Range'),
                    subtitle: Text(_dateRange == null 
                        ? 'All Time' 
                        : '${DateFormat.yMMMd().format(_dateRange!.start)} - ${DateFormat.yMMMd().format(_dateRange!.end)}'),
                    leading: const Icon(Icons.date_range),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setModalState(() => _dateRange = picked);
                      }
                    },
                    trailing: _dateRange != null ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setModalState(() => _dateRange = null),
                    ) : null,
                  ),
                  const Divider(),

                  // Type Filter
                  const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedType == null,
                        onSelected: (val) => setModalState(() => _selectedType = null),
                      ),
                      FilterChip(
                        label: const Text('Expense'),
                        selected: _selectedType == TransactionType.expense,
                        onSelected: (val) => setModalState(() => _selectedType = TransactionType.expense),
                      ),
                      FilterChip(
                        label: const Text('Income'),
                        selected: _selectedType == TransactionType.income,
                        onSelected: (val) => setModalState(() => _selectedType = TransactionType.income),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) => setModalState(() => _selectedCategory = val),
                  ),
                  
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {}); // Update main screen
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = Provider.of<ExpenseProvider>(context).transactions;
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;

    // Apply Filters
    final filteredTransactions = allTransactions.where((tx) {
      // 1. Date Filter
      if (_dateRange != null) {
        if (tx.date.isBefore(_dateRange!.start) || tx.date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      // 2. Type Filter
      if (_selectedType != null && tx.type != _selectedType) {
        return false;
      }
      // 3. Category Filter
      if (_selectedCategory != null && tx.categoryId != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            icon: Icon(_dateRange != null || _selectedCategory != null || _selectedType != null 
                ? Icons.filter_list_alt 
                : Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: filteredTransactions.isEmpty
          ? const Center(child: Text('No transactions found matching filters.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (ctx, index) {
                final tx = filteredTransactions[index];
                
                Category cat;
                try {
                  cat = categories.firstWhere((c) => c.id == tx.categoryId);
                } catch (e) {
                  cat = Category(id: 'unknown', name: 'Unknown', icon: Icons.question_mark, color: Colors.grey);
                }
                
                final isExpense = tx.type == TransactionType.expense;

                return Dismissible(
                  key: Key(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Transaction?'),
                        content: const Text('Are you sure you want to delete this transaction?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    Provider.of<ExpenseProvider>(context, listen: false).deleteTransaction(tx.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction deleted')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cat.color.withOpacity(0.2),
                        child: Icon(cat.icon, color: cat.color),
                      ),
                      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat.yMMMd().format(tx.date)),
                          if (tx.description != null && tx.description!.isNotEmpty)
                            Text(tx.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isExpense ? '-' : '+'} $currency${tx.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpense ? Colors.red : Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          _getMoodEmoji(tx.mood),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  Widget _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy: return const Text('😊', style: TextStyle(fontSize: 12));
      case Mood.sad: return const Text('😔', style: TextStyle(fontSize: 12));
      case Mood.neutral: return const SizedBox.shrink();
    }
  }
}
