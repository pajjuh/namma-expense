import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

enum TimeSpan { daily, monthly, yearly }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime? _selectedMonth = DateTime.now(); // null = Lifetime
  TimeSpan _timeSpan = TimeSpan.monthly;

  // Generate a list of months for the top selector (Lifetime + Last 11 months + Current)
  List<DateTime?> _getAvailableMonths() {
    final now = DateTime.now();
    List<DateTime?> months = [null]; // null represents "Lifetime"
    
    for (int i = 11; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }
    return months;
  }

  // Filter transactions based on selected month (if any)
  List<model.Transaction> _getFilteredTransactions(List<model.Transaction> allTxns) {
    if (_selectedMonth == null) return allTxns;

    return allTxns.where((tx) {
      return tx.date.year == _selectedMonth!.year &&
             tx.date.month == _selectedMonth!.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = Provider.of<ExpenseProvider>(context).transactions;
    final filteredTxns = _getFilteredTransactions(allTxns);
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate Totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in filteredTxns) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : Theme.of(context).colorScheme.surface;
    final cardColor = isDark ? const Color(0xFF161B22) : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor, // Dynamic background
      appBar: AppBar(
        title: Text('Financial Insights', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.share, size: 20, color: textColor),
            onPressed: () {}, // Future share feature
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Month Selector Strip
            _buildMonthSelector(screenWidth, isDark, textColor),
            SizedBox(height: screenHeight * 0.03),

            // 2. Summary Cards (Income & Expense)
            Row(
              children: [
                Expanded(child: _buildSummaryCard('INCOME', totalIncome, currency, true, screenWidth, cardColor, borderColor, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('EXPENSE', totalExpense, currency, false, screenWidth, cardColor, borderColor, isDark)),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),

            // 3. Time Span Toggle
            _buildTimeToggle(screenWidth, cardColor, borderColor, isDark),
            SizedBox(height: screenHeight * 0.03),

            // 4. Spending Trends Chart
            _buildSpendingTrendsCard(filteredTxns, screenWidth, screenHeight, cardColor, borderColor, textColor, subtitleColor, isDark),
            SizedBox(height: screenHeight * 0.03),

            // 5. Category Distribution
            _buildCategoryDistributionCard(filteredTxns, currency, screenWidth, screenHeight, cardColor, borderColor, textColor, subtitleColor, isDark),
            SizedBox(height: screenHeight * 0.03),

            // 6. Split Brain Insights
            SplitBrainInsights(isDark: isDark, cardColor: cardColor, borderColor: borderColor, textColor: textColor, subtitleColor: subtitleColor),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  // Horizontal scroller for Months
  Widget _buildMonthSelector(double screenWidth, bool isDark, Color textColor) {
    final months = _getAvailableMonths();
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final monthDate = months[index];
          final isSelected = _selectedMonth == monthDate || 
                             (_selectedMonth != null && monthDate != null && 
                              _selectedMonth!.year == monthDate.year && 
                              _selectedMonth!.month == monthDate.month);
          
          String label = monthDate == null ? 'Lifetime' : DateFormat('MMMM').format(monthDate);

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _selectedMonth = monthDate;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5D5FEF) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.1) : Colors.transparent),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Income / Expense Dual Cards
  Widget _buildSummaryCard(String title, double amount, String currency, bool isIncome, double screenWidth, Color cardColor, Color borderColor, bool isDark) {
    final titleColor = isDark ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: titleColor, fontSize: 12, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$currency${amount.toStringAsFixed(2)}',
              style: TextStyle(
                // Use a slightly darker green/red in light mode for readability
                color: isIncome ? (isDark ? Colors.greenAccent : Colors.green.shade700) : (isDark ? Colors.redAccent : Colors.red.shade700),
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Daily / Monthly / Yearly Segmented Control
  Widget _buildTimeToggle(double screenWidth, Color cardColor, Color borderColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildToggleOption(TimeSpan.daily, 'Daily', isDark),
          _buildToggleOption(TimeSpan.monthly, 'Monthly', isDark),
          _buildToggleOption(TimeSpan.yearly, 'Yearly', isDark),
        ],
      ),
    );
  }

  Widget _buildToggleOption(TimeSpan span, String label, bool isDark) {
    final isSelected = _timeSpan == span;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _timeSpan = span;
            
            // Auto-adjust month selection to make sense with time span
            if (span == TimeSpan.yearly && _selectedMonth != null) {
              _selectedMonth = null; // Yearly usually implies lifetime/current year view
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5D5FEF) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Spending Trends Line Chart
  Widget _buildSpendingTrendsCard(List<model.Transaction> transactions, double screenWidth, double screenHeight, Color cardColor, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    // Generate data based on _timeSpan
    Map<String, double> chartData = _generateTrendData(transactions);
    
    // Find min/max for chart drawing
    double maxY = 0;
    if (chartData.isNotEmpty) {
      maxY = chartData.values.reduce((a, b) => a > b ? a : b);
    }
    // Pad maxY slightly so the line doesn't hit the absolute roof
    maxY = maxY == 0 ? 100 : maxY * 1.2;

    List<FlSpot> spots = [];
    List<String> xLabels = chartData.keys.toList();
    
    int index = 0;
    chartData.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value));
      index++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _timeSpan == TimeSpan.daily ? 'Last 7 Days' : 
                  _timeSpan == TimeSpan.monthly ? 'Weeks 1 - 4' : 'All Months',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.04),
          
          SizedBox(
            height: screenHeight * 0.25,
            child: spots.isEmpty 
              ? Center(child: Text('No spending data', style: TextStyle(color: subtitleColor)))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: false, // Hidden grids to match reference
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y-axis numbers
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < xLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  xLabels[value.toInt()],
                                  style: TextStyle(color: subtitleColor, fontSize: 12),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble() > 0 ? (spots.length - 1).toDouble() : 1,
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF5D5FEF),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF5D5FEF).withOpacity(0.3),
                              const Color(0xFF5D5FEF).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Generates aggregated data for the chart based on current TimeSpan
  Map<String, double> _generateTrendData(List<model.Transaction> txns) {
    Map<String, double> data = {};
    if (txns.isEmpty) return data;

    // Filter only expenses
    final expenses = txns.where((tx) => tx.type == TransactionType.expense).toList();

    if (_timeSpan == TimeSpan.daily) {
      // Last 7 days
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        data[DateFormat('E').format(d)] = 0; // Mon, Tue...
      }
      for (var tx in expenses) {
        final diff = now.difference(tx.date).inDays;
        if (diff >= 0 && diff < 7) {
          final key = DateFormat('E').format(tx.date);
          data[key] = (data[key] ?? 0) + tx.amount;
        }
      }
    } else if (_timeSpan == TimeSpan.monthly) {
      // Group by weeks in month
      data = {'W1': 0, 'W2': 0, 'W3': 0, 'W4': 0, 'W5': 0};
      
      for (var tx in expenses) {
        // If no month is selected, this chart groups ALL transactions by week of their respective months (which is odd).
        // Let's assume if Monthly is selected, we group by week-of-month.
        int weekNum = ((tx.date.day - 1) / 7).floor() + 1; 
        if (weekNum > 5) weekNum = 5;
        final key = 'W$weekNum';
        data[key] = (data[key] ?? 0) + tx.amount;
      }
      // Clean up empty W5 if unneeded to keep it similar to reference
      if (data['W5'] == 0) data.remove('W5');
      
    } else {
      // Yearly - group by Month
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (var m in months) {
        data[m] = 0;
      }
      for (var tx in expenses) {
        final key = DateFormat('MMM').format(tx.date);
        data[key] = (data[key] ?? 0) + tx.amount;
      }
      
      // Trim empty future months if looking at current year 
      // (Simplified approach: keep all 12 so the chart is full width)
    }

    return data;
  }

  // Category Distribution Donut Chart
  Widget _buildCategoryDistributionCard(List<model.Transaction> transactions, String currency, double screenWidth, double screenHeight, Color cardColor, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    final categories = Provider.of<UserProvider>(context, listen: false).categories;
    
    // Calculate category totals (Only Expenses)
    double totalExpense = 0;
    Map<String, double> catTotals = {};
    
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        catTotals[tx.categoryId] = (catTotals[tx.categoryId] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }

    // Sort categories by highest spend
    var sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors matching the reference image closely
    final List<Color> donutColors = [
      const Color(0xFF5D5FEF), // Purple
      const Color(0xFFFF8B20), // Orange
      const Color(0xFF00C48C), // Green
      const Color(0xFFFF4D4D), // Red
      Colors.pink,
      Colors.cyan,
    ];

    List<PieChartSectionData> sections = [];
    List<Widget> legendRows = [];
    
    if (totalExpense == 0) {
      sections.add(PieChartSectionData(color: Colors.grey.withOpacity(0.1), value: 1, radius: 25, title: ''));
    } else {
      int colorIndex = 0;
      for (var entry in sortedCats) {
        final color = donutColors[colorIndex % donutColors.length];
        final percentage = (entry.value / totalExpense) * 100;
        
        sections.add(
          PieChartSectionData(
            value: entry.value,
            title: '', // Text inside hidden, mapped to legend instead
            color: color,
            radius: 25,
          )
        );

        // Find Category Name
        Category? catObj;
        try {
          catObj = categories.firstWhere((c) => c.id == entry.key);
        } catch (e) {
          catObj = Category(id: entry.key, name: entry.key, icon: Icons.error, color: Colors.grey);
        }

        legendRows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(catObj.name, style: TextStyle(color: subtitleColor, fontSize: 13)),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          )
        );

        colorIndex++;
        if (colorIndex > 4) break; // Limit legend to top 5 to fit cleanly
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: screenHeight * 0.04),
          
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: screenWidth * 0.35,
                height: screenWidth * 0.35,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: screenWidth * 0.12,
                        sectionsSpace: 4,
                      ),
                    ),
                    // Centered Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('100%', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('TOTAL', style: TextStyle(color: subtitleColor, fontSize: 10, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              
              // Legends
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: legendRows.isEmpty 
                    ? [Text('No data yet', style: TextStyle(color: subtitleColor))] 
                    : legendRows,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Data-driven Brutal AI Insights — analyses REAL last 30 days of spending
class SplitBrainInsights extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;

  const SplitBrainInsights({
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final allTransactions = Provider.of<ExpenseProvider>(context).transactions;
    final currency = Provider.of<UserProvider>(context).currency;
    final categories = Provider.of<UserProvider>(context).categories;

    // Filter to last 30 days ONLY
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentTxns = allTransactions.where((tx) =>
      tx.type == TransactionType.expense &&
      tx.date.isAfter(thirtyDaysAgo)
    ).toList();

    if (recentTxns.isEmpty) return const SizedBox.shrink();

    List<Map<String, dynamic>> insights = [];

    // ─── 1. TIME-BASED ROAST (uses real tx.hour now!) ───
    double morningSpend = 0, afternoonSpend = 0, eveningSpend = 0, nightSpend = 0;
    for (var tx in recentTxns) {
      final h = tx.hour;
      if (h >= 6 && h < 12) morningSpend += tx.amount;
      else if (h >= 12 && h < 18) afternoonSpend += tx.amount;
      else if (h >= 18 && h < 24) eveningSpend += tx.amount;
      else nightSpend += tx.amount;
    }

    final totalSpend = morningSpend + afternoonSpend + eveningSpend + nightSpend;
    final timeSpends = {
      'morning': morningSpend,
      'afternoon': afternoonSpend, 
      'evening': eveningSpend,
      'night': nightSpend,
    };
    final topTime = timeSpends.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (topTime.value > 0) {
      final pct = ((topTime.value / totalSpend) * 100).toStringAsFixed(0);
      final amt = topTime.value.toStringAsFixed(0);
      
      // Roast templates per time bucket (rotating via day-of-month for variety)
      final dayOfMonth = now.day;
      
      String title, emoji, desc;
      switch (topTime.key) {
        case 'morning':
          emoji = '☀️';
          title = 'Early Bird Bankrupt';
          final morningRoasts = [
            'You spent $currency$amt before noon this month. Productivity? No. Consumer activity? Elite.',
            'Breakfast was supposed to be light. Your wallet disagrees. $currency$amt gone by noon ($pct% of all spending).',
            'Your day starts with spending. Bold strategy. $currency$amt in morning hours this month.',
          ];
          desc = morningRoasts[dayOfMonth % morningRoasts.length];
          break;
        case 'afternoon':
          emoji = '🌤️';
          title = 'Afternoon Slump Shopper';
          final afternoonRoasts = [
            '$currency$amt vanished between lunch and "just one quick break". That\'s $pct% of your spending.',
            'You call it a small purchase. Your bank calls it a pattern. $currency$amt in afternoon spending.',
            'Afternoons: where budgets go to take naps. $currency$amt this month, $pct% of total.',
          ];
          desc = afternoonRoasts[dayOfMonth % afternoonRoasts.length];
          break;
        case 'evening':
          emoji = '🌆';
          title = 'Evening Wallet Emptier';
          final eveningRoasts = [
            'You blew $currency$amt this month in the evenings. Your night self is financially unsupervised.',
            'Peak spending hours detected. Self-control not found. $currency$amt ($pct%) after 6 PM.',
            'You + evenings = "add to cart" speedrun. $currency$amt in evening transactions.',
          ];
          desc = eveningRoasts[dayOfMonth % eveningRoasts.length];
          break;
        default:
          emoji = '🌙';
          title = 'Midnight Mistake Maker';
          final nightRoasts = [
            '$currency$amt between midnight and 6 AM? That wasn\'t spending. That was a cry for help.',
            'Nothing good happens after midnight. Except your transactions apparently. $currency$amt worth.',
            'Sleep was an option. You chose spending. $currency$amt in late-night purchases this month.',
          ];
          desc = nightRoasts[dayOfMonth % nightRoasts.length];
      }
      
      insights.add({
        'title': title,
        'emoji': emoji,
        'desc': desc,
        'amt': '$currency$amt',
      });
    }

    // ─── 2. TOP CATEGORY ROAST ───
    Map<String, double> catTotals = {};
    for (var tx in recentTxns) {
      catTotals[tx.categoryId] = (catTotals[tx.categoryId] ?? 0) + tx.amount;
    }
    if (catTotals.isNotEmpty) {
      final topCat = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final catAmt = topCat.value.toStringAsFixed(0);
      
      // Find category name
      String catName = topCat.key;
      try {
        catName = categories.firstWhere((c) => c.id == topCat.key).name;
      } catch (_) {}

      final catLower = catName.toLowerCase();
      String catDesc;
      
      // Category-specific roasts
      if (catLower.contains('food') || catLower.contains('dinner') || catLower.contains('lunch') || catLower.contains('grocery') || catLower.contains('restaurant')) {
        final foodRoasts = [
          'You spent $currency$catAmt on $catName in 30 days. At this point, you\'re funding restaurants emotionally.',
          '$currency$catAmt on $catName. Your diet plan is strong. Your spending plan is not.',
          'Groceries? No. Gourmet lifestyle. $currency$catAmt on $catName this month.',
        ];
        catDesc = foodRoasts[now.day % foodRoasts.length];
      } else if (catLower.contains('shop') || catLower.contains('cloth') || catLower.contains('fashion')) {
        final shopRoasts = [
          '$currency$catAmt on $catName. Was it a need or a personality upgrade?',
          'You don\'t buy things. You adopt them. $currency$catAmt on $catName this month.',
          'Retail therapy is working. For the stores. $currency$catAmt on $catName.',
        ];
        catDesc = shopRoasts[now.day % shopRoasts.length];
      } else if (catLower.contains('transport') || catLower.contains('fuel') || catLower.contains('auto') || catLower.contains('uber') || catLower.contains('commute')) {
        final transRoasts = [
          '$currency$catAmt on $catName. You\'re commuting to financial instability.',
          'At this rate, buying the vehicle might\'ve been cheaper. $currency$catAmt on $catName.',
        ];
        catDesc = transRoasts[now.day % transRoasts.length];
      } else {
        final genericRoasts = [
          'Your top category is $catName at $currency$catAmt. At least you\'re consistent… consistently broke.',
          'If spending was a sport, $catName would be your championship event. $currency$catAmt this month.',
          'You and $catName? That\'s not a phase. That\'s a lifestyle. $currency$catAmt in 30 days.',
        ];
        catDesc = genericRoasts[now.day % genericRoasts.length];
      }

      insights.add({
        'title': '🏆 Top Category: $catName',
        'emoji': '💸',
        'desc': catDesc,
        'amt': '$currency$catAmt',
      });
    }

    // ─── 3. SPENDING STREAK ───
    Set<String> spendingDays = {};
    for (var tx in recentTxns) {
      spendingDays.add('${tx.date.year}-${tx.date.month}-${tx.date.day}');
    }
    // Count consecutive days ending today/yesterday
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    while (spendingDays.contains('${checkDate.year}-${checkDate.month}-${checkDate.day}')) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    if (streak >= 3) {
      final streakRoasts = [
        'You\'ve spent money $streak days in a row. Impressive. Terrifying. But impressive.',
        'Day $streak of continuous spending. Your wallet hasn\'t seen peace.',
        'You\'re on a $streak-day spending streak. Athletes train less consistently.',
      ];
      insights.add({
        'title': '🔥 $streak-Day Spending Streak',
        'emoji': '🔥',
        'desc': streakRoasts[now.day % streakRoasts.length],
        'amt': '',
      });
    }

    // ─── 4. BIG SPENDER ALERT ───
    if (recentTxns.isNotEmpty) {
      final biggestTx = recentTxns.reduce((a, b) => a.amount > b.amount ? a : b);
      final bigAmt = biggestTx.amount.toStringAsFixed(0);
      
      // Only show if the single transaction is significant (> 20% of total)
      if (biggestTx.amount > totalSpend * 0.15 && biggestTx.amount > 100) {
        final bigRoasts = [
          '$currency$bigAmt in one shot on "${biggestTx.title}". That wasn\'t spending. That was a financial plot twist.',
          'You didn\'t "buy" ${biggestTx.title}. You made a statement. $currency$bigAmt worth.',
          'Biggest hit this month: $currency$bigAmt on "${biggestTx.title}" at ${biggestTx.formattedTime}. Peak decision-making right there.',
        ];
        insights.add({
          'title': '🚨 Big Spender Alert',
          'emoji': '🚨',
          'desc': bigRoasts[now.day % bigRoasts.length],
          'amt': '$currency$bigAmt',
        });
      }
    }

    // ─── 5. WEEKEND vs WEEKDAY ───
    double weekdaySpend = 0, weekendSpend = 0;
    int weekdayCount = 0, weekendCount = 0;
    for (var tx in recentTxns) {
      if (tx.date.weekday >= 6) {
        weekendSpend += tx.amount;
        weekendCount++;
      } else {
        weekdaySpend += tx.amount;
        weekdayCount++;
      }
    }
    final avgWeekday = weekdayCount > 0 ? weekdaySpend / weekdayCount : 0;
    final avgWeekend = weekendCount > 0 ? weekendSpend / weekendCount : 0;

    if (avgWeekend > avgWeekday * 1.5 && weekendCount > 2) {
      final pctHigher = ((avgWeekend / (avgWeekday == 0 ? 1 : avgWeekday)) * 100).toStringAsFixed(0);
      insights.add({
        'title': 'Weekend Warrior (of Debt)',
        'emoji': '🎉',
        'desc': 'Monday-Friday you\'re a monk. Saturday? Tech CEO on a yacht. Weekend spending is $pctHigher% higher per transaction. Total weekend damage: $currency${weekendSpend.toStringAsFixed(0)}.',
        'amt': '',
      });
    } else if (avgWeekday > avgWeekend * 1.5 && weekdayCount > 5) {
      insights.add({
        'title': 'Corporate Capitalist',
        'emoji': '💼',
        'desc': 'Are you paying to go to work? You spend way more on weekdays ($currency${weekdaySpend.toStringAsFixed(0)}) than weekends ($currency${weekendSpend.toStringAsFixed(0)}). Try packing a lunch.',
        'amt': '',
      });
    }

    // ─── 6. MONTHLY TOTAL SUMMARY ───
    if (totalSpend > 0) {
      final summaryRoasts = [
        'This month you spent $currency${totalSpend.toStringAsFixed(0)}. Memories were made. Savings were not.',
        'Monthly total: $currency${totalSpend.toStringAsFixed(0)}. Your wallet would like a word.',
        'You earned money. Then you released it back into the wild. $currency${totalSpend.toStringAsFixed(0)} gone.',
      ];
      insights.add({
        'title': '📊 30-Day Damage Report',
        'emoji': '📊',
        'desc': summaryRoasts[now.day % summaryRoasts.length],
        'amt': '$currency${totalSpend.toStringAsFixed(0)}',
      });
    }

    // ─── 7. SELF-AWARENESS ROAST (rare, savage — 5% tone) ───
    // Only show on specific days for rarity
    if (now.day % 7 == 0 && recentTxns.length > 10) {
      final savageRoasts = [
        'You opened this app for insights. Here\'s one: stop.',
        'Tracking expenses doesn\'t reduce them. Evidence: you.',
        'At this point, your budget is just a suggestion document.',
        'You\'re not bad with money. You\'re just… creatively irresponsible.',
        'You\'re not tracking money. You\'re documenting chaos.',
      ];
      insights.add({
        'title': '🧠 Self-Awareness Check',
        'emoji': '🧠',
        'desc': savageRoasts[(now.day + now.month) % savageRoasts.length],
        'amt': '',
      });
    }

    // ─── 8. SMART COMBO ROAST (mix time + category) ───
    if (catTotals.isNotEmpty && topTime.value > 0) {
      final topCatEntry = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      String topCatName = topCatEntry.key;
      try {
        topCatName = categories.firstWhere((c) => c.id == topCatEntry.key).name;
      } catch (_) {}

      final timeLabel = {
        'morning': 'mornings (6 AM - 12 PM)',
        'afternoon': 'afternoons (12 - 6 PM)',
        'evening': 'evenings (6 PM - 12 AM)',
        'night': 'late nights (12 - 6 AM)',
      }[topTime.key]!;

      // Only show if there's an interesting combo (not on same day as self-awareness)
      if (now.day % 7 != 0 && now.day % 3 == 0) {
        insights.add({
          'title': '🧩 Pattern Detected',
          'emoji': '🧩',
          'desc': 'You spent $currency${topCatEntry.value.toStringAsFixed(0)} on $topCatName mostly during $timeLabel. That\'s not a habit. That\'s a ritual.',
          'amt': '',
        });
      }
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🧠', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('Brutal AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight['emoji'], style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(insight['title'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16))),
                        if (insight['amt'] != '')
                          Text(insight['amt'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(insight['desc'], style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
