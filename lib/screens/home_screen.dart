import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list.dart';
import '../widgets/daily_limit_slider.dart';
import '../widgets/floating_insight_bubble.dart';
import '../helpers/constants.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate today's spending
    final today = DateTime.now();
    final todaySpending = expenseProvider.transactions
        .where((t) {
          bool isExpense = t.type.index == 1;
          bool isManual = t.origin == TransactionOrigin.manual;
          bool includeInLimit = !userProvider.excludeSubsFromDailyLimit || isManual;
          
          return t.date.year == today.year &&
                 t.date.month == today.month &&
                 t.date.day == today.day &&
                 isExpense &&
                 includeInLimit;
        })
        .fold(0.0, (sum, t) => sum + t.amount);

    final isOverLimit = userProvider.dailyLimit > 0 && todaySpending > userProvider.dailyLimit;
    
    return SafeArea(
      child: Scaffold(
        body: ListView(
          children: [
            // Old warning banner removed

            // Custom Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, 
                vertical: screenHeight * 0.01,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        Text(
                          userProvider.userName.isEmpty ? 'Friend' : userProvider.userName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: screenWidth * 0.05,
                    backgroundColor: isOverLimit ? Colors.red : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      isOverLimit ? Icons.lock : Icons.person,
                      color: isOverLimit ? Colors.white : Theme.of(context).colorScheme.primary,
                      size: screenWidth * 0.05,
                    ),
                  ),
                ],
              ),
            ),

            // Floating Cruel Insight Bubble
            const FloatingInsightBubble(),
            
            // Balance Card
            const SummaryCard(),

            // Sass-O-Meter Spending Widget
            if (userProvider.dailyLimit > 0)
              DailyLimitSlider(
                todaySpending: todaySpending,
                dailyLimit: userProvider.dailyLimit,
              ),

            // Recent Transactions Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
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

            // Transaction List (already uses shrinkWrap + NeverScrollableScrollPhysics)
            const TransactionList(),
          ],
        ),
      ),
    );
  }
}
