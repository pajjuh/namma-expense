import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

class FloatingInsightBubble extends StatefulWidget {
  const FloatingInsightBubble({super.key});

  @override
  State<FloatingInsightBubble> createState() => _FloatingInsightBubbleState();
}

class _FloatingInsightBubbleState extends State<FloatingInsightBubble>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _dismissed = false;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnim = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _dismissed) return;
      _nextInsight();
    });
  }

  void _nextInsight() {
    _animController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentIndex++);
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _generateInsights(BuildContext context) {
    final allTxns = Provider.of<ExpenseProvider>(context, listen: false).transactions;
    final currency = Provider.of<UserProvider>(context, listen: false).currency;
    final categories = Provider.of<UserProvider>(context, listen: false).categories;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentExpenses = allTxns.where((tx) =>
      tx.type == TransactionType.expense &&
      tx.date.isAfter(thirtyDaysAgo)
    ).toList();

    if (recentExpenses.isEmpty) return [];

    List<Map<String, String>> roasts = [];
    final rng = Random(now.day + now.month);

    // Category totals
    Map<String, double> catTotals = {};
    for (var tx in recentExpenses) {
      catTotals[tx.categoryId] = (catTotals[tx.categoryId] ?? 0) + tx.amount;
    }

    // Per-category roasts
    for (var entry in catTotals.entries) {
      String catName = entry.key;
      try {
        catName = categories.firstWhere((c) => c.id == entry.key).name;
      } catch (_) {}

      final amt = '$currency${entry.value.toStringAsFixed(0)}';
      final catLower = catName.toLowerCase();

      if (catLower.contains('food') || catLower.contains('lunch') || catLower.contains('dinner') || catLower.contains('grocery') || catLower.contains('restaurant')) {
        roasts.addAll([
          {'text': '"$amt on $catName? At this point, you\'re funding restaurants emotionally."', 'emoji': '🍕'},
          {'text': '"$catName again? Your kitchen called. It misses you. $amt gone."', 'emoji': '🍳'},
          {'text': '"Is that a bribe for your liver so it doesn\'t quit on you? $amt on $catName."', 'emoji': '🔥'},
        ]);
      } else if (catLower.contains('shop') || catLower.contains('cloth') || catLower.contains('fashion')) {
        roasts.addAll([
          {'text': '"$amt on $catName. Was it a need or a personality upgrade?"', 'emoji': '🛍️'},
          {'text': '"You don\'t buy things. You adopt them. $amt on $catName."', 'emoji': '👗'},
          {'text': '"Retail therapy is working. For the stores. $amt."', 'emoji': '💅'},
        ]);
      } else if (catLower.contains('transport') || catLower.contains('fuel') || catLower.contains('auto') || catLower.contains('uber')) {
        roasts.addAll([
          {'text': '"$amt on $catName. You\'re commuting to financial instability."', 'emoji': '🚕'},
          {'text': '"At this rate, buying the vehicle might\'ve been cheaper. $amt."', 'emoji': '⛽'},
        ]);
      } else if (catLower.contains('entertain') || catLower.contains('movie') || catLower.contains('game')) {
        roasts.addAll([
          {'text': '"$amt on $catName. At least your entertainment budget has no chill."', 'emoji': '🎬'},
          {'text': '"Movies, games, fun — $amt worth. Your savings? On pause."', 'emoji': '🎮'},
        ]);
      } else if (catLower.contains('bill') || catLower.contains('recharge') || catLower.contains('electric')) {
        roasts.addAll([
          {'text': '"$amt on $catName. Adulting hits different, doesn\'t it?"', 'emoji': '💡'},
        ]);
      } else if (catLower.contains('health') || catLower.contains('medical') || catLower.contains('gym')) {
        roasts.addAll([
          {'text': '"$amt on $catName. At least your body is getting the investment your wallet is not."', 'emoji': '💪'},
        ]);
      } else {
        roasts.addAll([
          {'text': '"$amt on $catName this month. At least you\'re consistent… consistently broke."', 'emoji': '💸'},
          {'text': '"You and $catName? That\'s not a phase. That\'s a lifestyle. $amt."', 'emoji': '🎯'},
        ]);
      }
    }

    // Add some generic savage ones 
    final totalSpend = recentExpenses.fold(0.0, (sum, tx) => sum + tx.amount);
    roasts.addAll([
      {'text': '"Total damage this month: $currency${totalSpend.toStringAsFixed(0)}. Your wallet would like a word."', 'emoji': '📊'},
      {'text': '"Tracking expenses doesn\'t reduce them. Evidence: you."', 'emoji': '🧠'},
      {'text': '"Your budget is just a suggestion document at this point."', 'emoji': '📋'},
    ]);

    // Shuffle for variety
    roasts.shuffle(rng);
    return roasts;
  }

  @override
  Widget build(BuildContext context) {
    final showInsights = Provider.of<UserProvider>(context).showFloatingInsights;
    if (_dismissed || !showInsights) return const SizedBox.shrink();

    final insights = _generateInsights(context);
    if (insights.isEmpty) return const SizedBox.shrink();

    final insight = insights[_currentIndex % insights.length];
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 8,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Speech bubble body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 36, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.redAccent.withOpacity(0.3) : Colors.red.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.redAccent : Colors.red).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Fire icon badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(insight['emoji']!, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CRUEL INSIGHT',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: screenWidth * 0.028,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight['text']!,
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                            fontSize: screenWidth * 0.032,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Close button
            Positioned(
              right: 6,
              top: 6,
              child: GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close, 
                    size: 14, 
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            // Speech bubble tail (triangle)
            Positioned(
              bottom: -8,
              left: 30,
              child: CustomPaint(
                size: const Size(16, 8),
                painter: _BubbleTailPainter(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderColor: isDark ? Colors.redAccent.withOpacity(0.3) : Colors.red.withOpacity(0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the small triangle tail under the speech bubble
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
