import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../widgets/calc_bottom_sheet.dart';
import '../widgets/mood_selector.dart';
import 'package:nammaexpense/l10n/app_localizations.dart';

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
  TimeOfDay _selectedTime = TimeOfDay.now();
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
      _selectedTime = tx.timeOfDay;
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
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
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
        SnackBar(content: Text(AppLocalizations.of(context)!.categoryRequired)),
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

  void _presentTimePicker() {
    showTimePicker(
      context: context,
      initialTime: _selectedTime,
    ).then((pickedTime) {
      if (pickedTime == null) return;
      setState(() {
        _selectedTime = pickedTime;
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
      appBar: AppBar(title: Text(widget.existingTransaction != null ? AppLocalizations.of(context)!.editTransaction : AppLocalizations.of(context)!.addTransaction)),
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
                        segments: [
                          ButtonSegment(value: TransactionType.expense, label: Text(AppLocalizations.of(context)!.expense), icon: const Icon(Icons.arrow_downward)),
                          ButtonSegment(value: TransactionType.income, label: Text(AppLocalizations.of(context)!.income), icon: const Icon(Icons.arrow_upward)),
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
                          labelText: AppLocalizations.of(context)!.amount,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calculate_outlined, color: Theme.of(context).colorScheme.primary),
                            tooltip: 'Calculator',
                            onPressed: () async {
                              final result = await CalcBottomSheet.show(context, initialValue: _amountController.text);
                              if (result != null) {
                                _amountController.text = result == result.toInt().toDouble()
                                    ? result.toInt().toString()
                                    : result.toStringAsFixed(2);
                              }
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredField;
                          if (double.tryParse(val) == null) return AppLocalizations.of(context)!.invalidNumber;
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Title Input
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.title,
                          hintText: AppLocalizations.of(context)!.titleHint,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val!.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Category Selector
                      Text(AppLocalizations.of(context)!.category, style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: screenHeight * 0.01),
                      Builder(
                        builder: (context) {
                          final maxVisible = 7;
                          List<Category> visibleCats = categories.take(maxVisible).toList();
                          bool showMore = categories.length > maxVisible;
                          
                          if (_selectedCategory != null && !visibleCats.any((c) => c.id == _selectedCategory)) {
                            final selectedCatObj = categories.firstWhere((c) => c.id == _selectedCategory, orElse: () => categories.first);
                            if (visibleCats.length == maxVisible) {
                              visibleCats[maxVisible - 1] = selectedCatObj;
                            } else {
                              visibleCats.add(selectedCatObj);
                            }
                          }

                          return Wrap(
                            spacing: screenWidth * 0.02,
                            runSpacing: screenHeight * 0.01,
                            children: [
                              ...visibleCats.map((cat) {
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
                              }),
                              if (showMore)
                                ChoiceChip(
                                  label: Text(AppLocalizations.of(context)!.more),
                                  avatar: Icon(Icons.more_horiz, size: screenWidth * 0.04),
                                  selected: false,
                                  onSelected: (_) {
                                    _showCategoryPicker(context, categories);
                                  },
                                ),
                            ],
                          );
                        }
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Wallet & Date Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<WalletType>(
                              value: _selectedWallet,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.wallet, 
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: WalletType.values.map((w) {
                                return DropdownMenuItem(value: w, child: Text(w.name.toUpperCase()));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedWallet = val!),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              onTap: _presentDatePicker,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.date, 
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(DateFormat.MMMd().format(_selectedDate), style: TextStyle(fontSize: screenWidth * 0.033)),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _presentTimePicker,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time', 
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(_selectedTime.format(context), style: TextStyle(fontSize: screenWidth * 0.033)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Mood Selector
                      if (_type == TransactionType.expense) ...[
                        Text(AppLocalizations.of(context)!.howDidYouFeel, style: Theme.of(context).textTheme.titleMedium),
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
                          label: Text(widget.existingTransaction != null ? AppLocalizations.of(context)!.updateTransaction : AppLocalizations.of(context)!.saveTransaction),
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

  void _showCategoryPicker(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.allCategories, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat.id;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: cat.color.withOpacity(0.2),
                              child: Icon(cat.icon, color: cat.color, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
