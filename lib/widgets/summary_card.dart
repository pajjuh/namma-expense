import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive values
    final cardMargin = screenWidth * 0.04;
    final cardPadding = screenWidth * 0.05;
    final titleFontSize = screenWidth * 0.04;
    final balanceFontSize = screenWidth * 0.08;
    final indicatorFontSize = screenWidth * 0.045;
    final iconSize = screenWidth * 0.04;

    return Container(
      margin: EdgeInsets.all(cardMargin),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontSize: titleFontSize),
              ),
              _buildFilterDropdown(context, expenseProvider),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$currency ${expenseProvider.filteredBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: balanceFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              _buildIndicator(
                context: context,
                label: 'Income',
                amount: '$currency ${expenseProvider.filteredIncome.toStringAsFixed(0)}',
                icon: Icons.arrow_upward,
                color: Colors.greenAccent,
                iconSize: iconSize,
                fontSize: indicatorFontSize,
              ),
              Container(
                width: 1, 
                height: screenHeight * 0.05, 
                color: Colors.white24,
              ),
              _buildIndicator(
                context: context,
                label: 'Expense',
                amount: '$currency ${expenseProvider.filteredExpense.toStringAsFixed(0)}',
                icon: Icons.arrow_downward,
                color: Colors.redAccent,
                iconSize: iconSize,
                fontSize: indicatorFontSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required BuildContext context,
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
    required double iconSize,
    required double fontSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: iconSize),
              SizedBox(width: screenWidth * 0.01),
              Text(
                label, 
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, ExpenseProvider expenseProvider) {
    return PopupMenuButton<DashboardTimeFilter>(
      initialValue: expenseProvider.dashboardFilter,
      onSelected: (DashboardTimeFilter filter) {
        expenseProvider.setDashboardFilter(filter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getFilterLabel(expenseProvider.dashboardFilter),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: DashboardTimeFilter.day,
          child: Text('Today'),
        ),
        const PopupMenuItem(
          value: DashboardTimeFilter.week,
          child: Text('This Week (7 days)'),
        ),
        const PopupMenuItem(
          value: DashboardTimeFilter.month,
          child: Text('This Month'),
        ),
        const PopupMenuItem(
          value: DashboardTimeFilter.lifetime,
          child: Text('Lifetime'),
        ),
      ],
    );
  }

  String _getFilterLabel(DashboardTimeFilter filter) {
    switch (filter) {
      case DashboardTimeFilter.day:
        return 'Today';
      case DashboardTimeFilter.week:
        return 'Week';
      case DashboardTimeFilter.month:
        return 'Month';
      case DashboardTimeFilter.lifetime:
        return 'Lifetime';
    }
  }
}
