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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.6,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            top: screenHeight * 0.02,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _getContextMessage(), 
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: screenHeight * 0.02),
              
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
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Text('Quick Category', style: Theme.of(context).textTheme.labelLarge),
              SizedBox(height: screenHeight * 0.01),
              Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.01,
                children: contextCategories.map((cat) {
                  return ChoiceChip(
                    label: Text(
                      cat.name,
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    avatar: Icon(cat.icon, size: screenWidth * 0.035),
                    selected: _selectedCategory == cat.id,
                    onSelected: (val) => setState(() => _selectedCategory = val ? cat.id : null),
                  );
                }).toList(),
              ),
              SizedBox(height: screenHeight * 0.02),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Quick Save'),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
