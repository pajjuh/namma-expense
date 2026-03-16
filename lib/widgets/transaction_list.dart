import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../screens/add_transaction_screen.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<ExpenseProvider>(context).transactions;
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long, 
              size: screenWidth * 0.15, 
              color: Colors.grey.shade300,
            ),
            SizedBox(height: screenHeight * 0.02),
            const Text('No transactions yet.\nAdd one to get started!', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Only show last 5 transactions in this summary list
    final recentTxns = transactions.take(5).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTxns.length,
      itemBuilder: (ctx, i) {
        final tx = recentTxns[i];
        Category? cat;
        try {
          cat = categories.firstWhere((c) => c.id == tx.categoryId);
        } catch (e) {
          cat = Category(id: tx.categoryId, name: tx.categoryId, icon: Icons.category, color: Colors.grey);
        }
        final isExpense = tx.type == TransactionType.expense;

        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, 
            vertical: screenHeight * 0.007,
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(existingTransaction: tx),
                ),
              );
            },
            leading: CircleAvatar(
              radius: screenWidth * 0.05,
              backgroundColor: cat.color.withOpacity(0.2),
              child: Icon(cat.icon, color: cat.color, size: screenWidth * 0.05),
            ),
            title: Text(
              tx.title, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
            subtitle: Text(
              DateFormat.yMMMd().format(tx.date),
              style: TextStyle(fontSize: screenWidth * 0.032),
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
        );
      },
    );
  }
}
