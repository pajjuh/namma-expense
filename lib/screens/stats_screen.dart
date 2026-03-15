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

// AI insights logic with extended funny responses and dynamic theming
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
    final transactions = Provider.of<ExpenseProvider>(context).transactions;
    final currency = Provider.of<UserProvider>(context).currency;

    if (transactions.isEmpty) return const SizedBox.shrink();

    double morningSpend = 0, afternoonSpend = 0, eveningSpend = 0, nightSpend = 0;
    double weekdaySpend = 0, weekendSpend = 0;
    int weekdayCount = 0, weekendCount = 0;

    for (var tx in transactions) {
      if (tx.type.index != 1) continue; 
      final hour = tx.date.hour;
      final isWeekend = tx.date.weekday >= 6;

      if (hour >= 6 && hour < 12) morningSpend += tx.amount;
      else if (hour >= 12 && hour < 17) afternoonSpend += tx.amount;
      else if (hour >= 17 && hour < 21) eveningSpend += tx.amount;
      else nightSpend += tx.amount;

      if (isWeekend) { weekendSpend += tx.amount; weekendCount++; } 
      else { weekdaySpend += tx.amount; weekdayCount++; }
    }

    List<Map<String, dynamic>> insights = [];
    final maxTimeSpend = [morningSpend, afternoonSpend, eveningSpend, nightSpend].reduce((a, b) => a > b ? a : b);
    
    // Funny Time Insights
    if (maxTimeSpend > 0) {
      String timeLabel = '';
      String timeEmoji = '';
      String timeDesc = '';

      if (maxTimeSpend == morningSpend) {
        timeLabel = 'Early Bird Bankrupt';
        timeEmoji = '☀️';
        timeDesc = 'You literally wake up and choose consumerism. Did you even brush your teeth before buying that? Maybe try coffee at home tomorrow instead of funding your local barista\'s new Tesla.';
      } else if (maxTimeSpend == afternoonSpend) {
        timeLabel = 'Afternoon Slump Shopper';
        timeEmoji = '🌤️';
        timeDesc = 'Ahh, the classic 2 PM urge to buy useless things to feel alive at your desk. Your boss thinks you\'re working on that spreadsheet, but we both know you\'re browsing Amazon.';
      } else if (maxTimeSpend == eveningSpend) {
        timeLabel = 'Twilight Treasurer';
        timeEmoji = '🌆';
        timeDesc = 'Sun goes down, wallet opens up. Dinner? Yes. Drinks? Obviously. Movie? Why not. You are the reason the nighttime economy is thriving, but your savings account is crying.';
      } else {
        timeLabel = 'Midnight Mistake Maker';
        timeEmoji = '🌙';
        timeDesc = 'Nothing good happens after 2 AM, especially on your credit card statement. Go to sleep! Stop buying weird gadgets from Instagram ads that you\'ll never use!';
      }

      insights.add({
        'title': timeLabel, 
        'emoji': timeEmoji,
        'desc': timeDesc,
        'amt': '$currency${maxTimeSpend.toStringAsFixed(0)}',
      });
    }

    // Funny Weekend Insights
    final avgWeekday = weekdayCount > 0 ? weekdaySpend / weekdayCount : 0;
    final avgWeekend = weekendCount > 0 ? weekendSpend / weekendCount : 0;
    
    if (avgWeekend > avgWeekday * 1.5) {
      insights.add({
        'title': 'Weekend Warrior (of Debt)',
        'emoji': '🎉',
        'desc': 'You\'re practically a monk from Monday to Friday, but come Saturday you spend money like a tech CEO on a yacht. Your weekend spending is ${((avgWeekend / (avgWeekday == 0 ? 1 : avgWeekday)) * 100).toStringAsFixed(0)}% violently higher.',
        'amt': '',
      });
    } else if (avgWeekday > avgWeekend * 1.5) {
      insights.add({
        'title': 'Corporate Capitalist',
        'emoji': '💼',
        'desc': 'Are you paying to go to work? You spend way more during the week than on weekends. Try packing a lunch before you accidentally buy the whole food court.',
        'amt': '',
      });
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('🧠', style: TextStyle(fontSize: 24)),
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
