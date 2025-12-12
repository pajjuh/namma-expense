import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list.dart';
import 'all_transactions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    
    // Calculate today's spending
    final today = DateTime.now();
    final todaySpending = expenseProvider.transactions
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day &&
            t.type.index == 1) // Expense
        .fold(0.0, (sum, t) => sum + t.amount);

    final isOverLimit = userProvider.dailyLimit > 0 && todaySpending > userProvider.dailyLimit;
    
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // Daily Limit Warning
            if (isOverLimit)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ You exceeded your daily limit of ${userProvider.currency}${userProvider.dailyLimit.toStringAsFixed(0)}!',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        userProvider.userName.isEmpty ? 'Friend' : userProvider.userName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: isOverLimit ? Colors.red : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      isOverLimit ? Icons.lock : Icons.person,
                      color: isOverLimit ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Balance Card
            const SummaryCard(),

            // Recent Transactions Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllTransactionsScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // List
            const Expanded(
              child: SingleChildScrollView(
                child: TransactionList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
