import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../widgets/mood_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  Mood _selectedMood = Mood.neutral;
  WalletType _selectedWallet = WalletType.upi;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _descController.text = tx.description ?? '';
      _selectedDate = tx.date;
      _type = tx.type;
      _selectedCategory = tx.categoryId;
      _selectedMood = tx.mood;
      _selectedWallet = tx.wallet;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final newTx = Transaction(
        id: widget.existingTransaction?.id, // Keep existing ID if editing
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        categoryId: _selectedCategory!,
        type: _type,
        mood: _selectedMood,
        wallet: _selectedWallet,
        description: _descController.text,
      );

      if (widget.existingTransaction != null) {
        Provider.of<ExpenseProvider>(context, listen: false).updateTransaction(newTx);
      } else {
        Provider.of<ExpenseProvider>(context, listen: false).addTransaction(newTx);
      }
      Navigator.of(context).pop();
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existingTransaction != null ? 'Edit Transaction' : 'Add Transaction')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - screenWidth * 0.08),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Toggle
                      SegmentedButton<TransactionType>(
                        segments: const [
                          ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                          ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                        ],
                        selected: {_type},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _type = newSelection.first;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: screenWidth * 0.07, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: '$currency ',
                          labelText: 'Amount',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) return 'Invalid Number';
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Title Input
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Lunch, Salary',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Category Selector
                      Text('Category', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: screenHeight * 0.01),
                      Wrap(
                        spacing: screenWidth * 0.02,
                        runSpacing: screenHeight * 0.01,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat.id;
                          return ChoiceChip(
                            label: Text(cat.name),
                            avatar: Icon(cat.icon, size: screenWidth * 0.04),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat.id : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Wallet & Date Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<WalletType>(
                              value: _selectedWallet,
                              decoration: const InputDecoration(
                                labelText: 'Wallet', 
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: WalletType.values.map((w) {
                                return DropdownMenuItem(value: w, child: Text(w.name.toUpperCase()));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedWallet = val!),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: InkWell(
                              onTap: _presentDatePicker,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date', 
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(DateFormat.yMMMd().format(_selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Mood Selector
                      if (_type == TransactionType.expense) ...[
                        Text('How did you feel?', style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: screenHeight * 0.01),
                        MoodSelector(
                          selectedMood: _selectedMood,
                          onMoodSelected: (m) => setState(() => _selectedMood = m),
                        ),
                        SizedBox(height: screenHeight * 0.025),
                      ],

                      // Spacer to push button down
                      const Spacer(),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveTransaction,
                          icon: const Icon(Icons.check),
                          label: Text(widget.existingTransaction != null ? 'Update Transaction' : 'Save Transaction'),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
