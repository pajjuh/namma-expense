import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Categories'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Heatmap'),
            Tab(icon: Icon(Icons.psychology), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CategoryPieChart(),
          HeatmapView(),
          SplitBrainInsights(),
        ],
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final categorySpending = Provider.of<ExpenseProvider>(context).categorySpending;
    final categories = Provider.of<UserProvider>(context).categories;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (categorySpending.isEmpty) {
      return const Center(
        child: Text('No expense data yet.\nAdd some transactions to see charts!', textAlign: TextAlign.center),
      );
    }

    final total = categorySpending.values.fold(0.0, (sum, val) => sum + val);

    // Build pie sections
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    categorySpending.forEach((catId, amount) {
      Category? cat;
      try {
        cat = categories.firstWhere((c) => c.id == catId);
      } catch (e) {
        cat = Category(id: catId, name: catId, icon: Icons.category, color: Colors.grey);
      }

      final percentage = (amount / total * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          value: amount,
          title: '$percentage%',
          color: cat.color,
          radius: screenWidth * 0.2,
          titleStyle: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: screenWidth * 0.03,
          ),
        ),
      );

      legendItems.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.04, 
                height: screenWidth * 0.04, 
                decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(child: Text(cat.name)),
              Text(
                '$currency${amount.toStringAsFixed(0)}', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    });

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            height: screenHeight * 0.3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: screenWidth * 0.12,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: screenHeight * 0.01),
                ...legendItems,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeatmapView extends StatelessWidget {
  const HeatmapView({super.key});

  @override
  Widget build(BuildContext context) {
    final heatmapData = Provider.of<ExpenseProvider>(context).heathMapData;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (heatmapData.isEmpty) {
      return const Center(child: Text('No data for heatmap yet.'));
    }

    // Find max for color scaling
    final maxVal = heatmapData.values.reduce((a, b) => a > b ? a : b);

    // Calculate cell size based on screen width (7 cells per row with spacing)
    final cellSize = (screenWidth - screenWidth * 0.12) / 7 - 4; // 7 days per row

    // Get last 35 days
    final today = DateTime.now();
    List<Widget> dayWidgets = [];

    for (int i = 34; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final value = heatmapData[dateKey] ?? 0;

      // Color intensity
      Color color;
      if (value == 0) {
        color = Colors.grey.shade200;
      } else {
        final intensity = (value / maxVal).clamp(0.0, 1.0);
        if (intensity < 0.33) {
          color = Colors.green.shade300;
        } else if (intensity < 0.66) {
          color = Colors.orange.shade400;
        } else {
          color = Colors.red.shade500;
        }
      }

      dayWidgets.add(
        Tooltip(
          message: '${date.day}/${date.month}: $currency$value',
          child: Container(
            margin: const EdgeInsets.all(2),
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(cellSize * 0.15),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: cellSize * 0.3,
                  color: value > 0 ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 35 Days Spending', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: screenHeight * 0.01),
          Row(
            children: [
              _buildLegendItem('Low', Colors.green.shade300, screenWidth),
              _buildLegendItem('Medium', Colors.orange.shade400, screenWidth),
              _buildLegendItem('High', Colors.red.shade500, screenWidth),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Wrap(children: dayWidgets),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.04),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.03, 
            height: screenWidth * 0.03, 
            decoration: BoxDecoration(
              color: color, 
              borderRadius: BorderRadius.circular(screenWidth * 0.008),
            ),
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(label, style: TextStyle(fontSize: screenWidth * 0.03)),
        ],
      ),
    );
  }
}

// Split Brain Mode - Spending Pattern Analysis
class SplitBrainInsights extends StatelessWidget {
  const SplitBrainInsights({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<ExpenseProvider>(context).transactions;
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (transactions.isEmpty) {
      return const Center(child: Text('Add more transactions to see insights!'));
    }

    // Analyze spending patterns
    double morningSpend = 0, afternoonSpend = 0, eveningSpend = 0, nightSpend = 0;
    double weekdaySpend = 0, weekendSpend = 0;
    int weekdayCount = 0, weekendCount = 0;

    for (var tx in transactions) {
      if (tx.type.index != 1) continue; // Only expenses

      final hour = tx.date.hour;
      final isWeekend = tx.date.weekday >= 6;

      if (hour >= 6 && hour < 12) {
        morningSpend += tx.amount;
      } else if (hour >= 12 && hour < 17) {
        afternoonSpend += tx.amount;
      } else if (hour >= 17 && hour < 21) {
        eveningSpend += tx.amount;
      } else {
        nightSpend += tx.amount;
      }

      if (isWeekend) {
        weekendSpend += tx.amount;
        weekendCount++;
      } else {
        weekdaySpend += tx.amount;
        weekdayCount++;
      }
    }

    // Generate insights
    List<Map<String, dynamic>> insights = [];

    // Time of day insight
    final maxTimeSpend = [morningSpend, afternoonSpend, eveningSpend, nightSpend].reduce((a, b) => a > b ? a : b);
    String timeLabel = '';
    String timeEmoji = '';
    if (maxTimeSpend == morningSpend) {
      timeLabel = 'Morning Spender';
      timeEmoji = '☀️';
    } else if (maxTimeSpend == afternoonSpend) {
      timeLabel = 'Afternoon Shopper';
      timeEmoji = '🌤️';
    } else if (maxTimeSpend == eveningSpend) {
      timeLabel = 'Evening Explorer';
      timeEmoji = '🌆';
    } else {
      timeLabel = 'Midnight Spender';
      timeEmoji = '🌙';
    }
    insights.add({
      'title': timeLabel,
      'emoji': timeEmoji,
      'description': 'You spend the most during this time of day.',
      'amount': '$currency${maxTimeSpend.toStringAsFixed(0)}',
    });

    // Weekend vs Weekday
    final avgWeekday = weekdayCount > 0 ? weekdaySpend / weekdayCount : 0;
    final avgWeekend = weekendCount > 0 ? weekendSpend / weekendCount : 0;
    if (avgWeekend > avgWeekday * 1.5) {
      insights.add({
        'title': 'Weekend Splurger',
        'emoji': '🎉',
        'description': 'Your weekend spending is ${((avgWeekend / (avgWeekday == 0 ? 1 : avgWeekday)) * 100).toStringAsFixed(0)}% higher than weekdays!',
        'amount': '',
      });
    } else if (avgWeekday > avgWeekend * 1.5) {
      insights.add({
        'title': 'Weekday Warrior',
        'emoji': '💼',
        'description': 'You spend more during work days than weekends.',
        'amount': '',
      });
    }

    // Night owl check
    if (nightSpend > (morningSpend + afternoonSpend + eveningSpend) / 3) {
      insights.add({
        'title': 'Night Owl Alert',
        'emoji': '🦉',
        'description': 'You make a lot of purchases late at night. Consider sleeping on big decisions!',
        'amount': '',
      });
    }

    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: [
        Text('🧠 Split Brain Analysis', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: screenHeight * 0.01),
        Text(
          'Understanding your spending psychology',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        SizedBox(height: screenHeight * 0.03),
        ...insights.map((insight) => _buildInsightCard(context, insight, screenWidth)),
        SizedBox(height: screenHeight * 0.02),
        // Time breakdown
        Card(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending by Time', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: screenHeight * 0.015),
                _buildTimeBar('Morning', morningSpend, maxTimeSpend, Colors.amber, currency, screenWidth),
                _buildTimeBar('Afternoon', afternoonSpend, maxTimeSpend, Colors.orange, currency, screenWidth),
                _buildTimeBar('Evening', eveningSpend, maxTimeSpend, Colors.deepPurple, currency, screenWidth),
                _buildTimeBar('Night', nightSpend, maxTimeSpend, Colors.indigo, currency, screenWidth),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> insight, double screenWidth) {
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: ListTile(
        leading: Text(insight['emoji'], style: TextStyle(fontSize: screenWidth * 0.08)),
        title: Text(insight['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(insight['description']),
        trailing: insight['amount'].toString().isNotEmpty
            ? Text(
                insight['amount'], 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
              )
            : null,
      ),
    );
  }

  Widget _buildTimeBar(String label, double amount, double max, Color color, String currency, double screenWidth) {
    final percentage = max > 0 ? (amount / max) : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        children: [
          SizedBox(width: screenWidth * 0.18, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: screenWidth * 0.025,
              borderRadius: BorderRadius.circular(screenWidth * 0.012),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          SizedBox(
            width: screenWidth * 0.15, 
            child: Text(
              '$currency${amount.toStringAsFixed(0)}', 
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
