import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  // Context-Aware Category Selection
  List<Category> _getContextCategories(List<Category> allCategories) {
    final hour = DateTime.now().hour;
    final isWeekend = DateTime.now().weekday >= 6;

    // Define context-based category IDs
    List<String> priorityIds;

    if (hour >= 6 && hour < 11) {
      // Morning: Breakfast, Transport, Coffee
      priorityIds = ['food', 'transport', 'recharge'];
    } else if (hour >= 11 && hour < 15) {
      // Afternoon: Lunch, Work
      priorityIds = ['food', 'bills', 'grocery'];
    } else if (hour >= 15 && hour < 19) {
      // Evening: Snacks, Shopping
      priorityIds = ['food', 'shopping', 'entertainment'];
    } else {
      // Night: Dinner, Entertainment
      priorityIds = ['food', 'entertainment', 'fuel'];
    }

    // Weekend override
    if (isWeekend) {
      priorityIds = ['entertainment', 'shopping', 'food', 'travel'];
    }

    // Filter and reorder categories based on priority
    List<Category> result = [];
    for (var id in priorityIds) {
      final found = allCategories.where((c) => c.id == id).toList();
      if (found.isNotEmpty && !result.contains(found.first)) {
        result.add(found.first);
      }
    }
    // Fill remaining slots with other categories
    for (var cat in allCategories) {
      if (!result.contains(cat) && result.length < 4) {
        result.add(cat);
      }
    }
    return result.take(4).toList();
  }

  String _getContextMessage() {
    final hour = DateTime.now().hour;
    final isWeekend = DateTime.now().weekday >= 6;

    if (isWeekend) return '🎉 Weekend Mode! Quick Add:';
    if (hour >= 6 && hour < 11) return '☀️ Good Morning! Quick Add:';
    if (hour >= 11 && hour < 15) return '🌤️ Lunch Time? Quick Add:';
    if (hour >= 15 && hour < 19) return '🌆 Evening Spend? Quick Add:';
    return '🌙 Night Owl? Quick Add:';
  }

  void _submit() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;
    
    setState(() => _isLoading = true);

    final newTx = Transaction(
      title: _titleController.text.isEmpty ? _selectedCategory! : _titleController.text,
      amount: double.parse(_amountController.text),
      date: DateTime.now(), // Always today
      categoryId: _selectedCategory!,
      type: TransactionType.expense, // Always expense for quick add
      mood: Mood.neutral, // Default
      wallet: WalletType.upi, // Default
    );

    await Provider.of<ExpenseProvider>(context, listen: false).addTransaction(newTx);
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = Provider.of<UserProvider>(context).categories;
    final contextCategories = _getContextCategories(allCategories);
    final currency = Provider.of<UserProvider>(context).currency;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_getContextMessage(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixText: '$currency ',
                    labelText: 'Amount',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Quick Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: contextCategories.map((cat) {
              return ChoiceChip(
                label: Text(cat.name),
                avatar: Icon(cat.icon, size: 14),
                selected: _selectedCategory == cat.id,
                onSelected: (val) => setState(() => _selectedCategory = val ? cat.id : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Quick Save'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
