import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({super.key});

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  // Start with 3 empty rows
  List<Map<String, dynamic>> _entries = [
    {'amount': TextEditingController(), 'note': TextEditingController(), 'category': null},
    {'amount': TextEditingController(), 'note': TextEditingController(), 'category': null},
    {'amount': TextEditingController(), 'note': TextEditingController(), 'category': null},
  ];

  void _addNewRow() {
    setState(() {
      _entries.add({
        'amount': TextEditingController(),
        'note': TextEditingController(),
        'category': null
      });
    });
  }

  void _removeRow(int index) {
    if (_entries.length > 1) {
      setState(() {
        _entries.removeAt(index);
      });
    }
  }

  void _saveAll() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    int savedCount = 0;

    for (var entry in _entries) {
      final amountText = entry['amount'].text;
      final categoryId = entry['category'];
      final note = entry['note'].text;

      if (amountText.isNotEmpty && categoryId != null) {
        final amount = double.tryParse(amountText);
        if (amount != null && amount > 0) {
          final newTx = Transaction(
            title: note.isEmpty ? categoryId : note, // Default title to category name if note empty
            amount: amount,
            date: DateTime.now(),
            categoryId: categoryId,
            type: TransactionType.expense,
            mood: Mood.neutral,
            wallet: WalletType.upi,
          );
          await provider.addTransaction(newTx);
          savedCount++;
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $savedCount transactions!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Add 📦'),
        actions: [
          IconButton(onPressed: _addNewRow, icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.04),
              itemCount: _entries.length,
              itemBuilder: (ctx, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth * 0.04,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: screenWidth * 0.035),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: TextField(
                                controller: _entries[index]['amount'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  prefixText: '$currency ',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: screenHeight * 0.015,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeRow(index),
                              icon: Icon(Icons.close, color: Colors.grey, size: screenWidth * 0.05),
                            )
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _entries[index]['category'],
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: screenHeight * 0.012,
                                  ),
                                ),
                                items: categories.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Icon(c.icon, size: screenWidth * 0.04),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: screenWidth * 0.032),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() => _entries[index]['category'] = val);
                                },
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _entries[index]['note'],
                                decoration: InputDecoration(
                                  labelText: 'Note (Optional)',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: screenHeight * 0.015,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.done_all),
                label: Text('Save All', style: TextStyle(fontSize: screenWidth * 0.045)),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
