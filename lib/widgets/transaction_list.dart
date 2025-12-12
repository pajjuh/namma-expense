import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<ExpenseProvider>(context).recentTransactions;
    final allCategories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;

    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No transactions yet. Add one!'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (ctx, index) {
        final tx = transactions[index];
        
        // Find Category Info
        // Note: In real app, we should merge all mode categories or store full category object, 
        // but here we check current mode list. If not found, use a fallback.
        Category cat;
        try {
          cat = allCategories.firstWhere((c) => c.id == tx.categoryId);
        } catch (e) {
          cat = Category(id: 'unknown', name: 'Unknown', icon: Icons.question_mark, color: Colors.grey);
        }

        final isExpense = tx.type == TransactionType.expense;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: cat.color.withOpacity(0.2),
            child: Icon(cat.icon, color: cat.color),
          ),
          title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat.yMMMd().format(tx.date)),
          trailing: Text(
            '${isExpense ? '-' : '+'} $currency${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
