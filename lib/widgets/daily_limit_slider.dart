import 'package:flutter/material.dart';

class DailyLimitSlider extends StatelessWidget {
  final double todaySpending;
  final double dailyLimit;

  const DailyLimitSlider({
    super.key,
    required this.todaySpending,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyLimit <= 0) return const SizedBox.shrink();

    double percentage = todaySpending / dailyLimit;
    if (percentage > 1.0) percentage = 1.0;
    if (percentage < 0.0) percentage = 0.0;

    // Funny level data based on spending percentage
    final level = _getLevel(percentage, todaySpending >= dailyLimit);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Spend-o-Meter 💸',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: level.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level.badge,
                  style: TextStyle(
                    color: level.badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Animated Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 10,
                width: (MediaQuery.of(context).size.width - 72) * percentage,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: level.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Emoji Thumb
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                left: ((MediaQuery.of(context).size.width - 72) * percentage) - 10,
                top: -9,
                child: Text(
                  level.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sassy Quote
          Text(
            '"${level.quote}"',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  _SassLevel _getLevel(double percentage, bool exceeded) {
    if (exceeded) {
      return _SassLevel(
        badge: '☠️ RIP WALLET',
        emoji: '💀',
        badgeColor: Colors.red,
        gradientColors: [Colors.red.shade400, Colors.red.shade700],
        quote: _randomQuote([
          "Your wallet just filed for divorce.",
          "Congrats, you've speedrun poverty!",
          "Broke-ology: The study of your spending habits.",
          "Even your piggy bank is crying right now.",
          "This is not a drill. Wallet is flatlined.",
        ]),
      );
    } else if (percentage >= 0.7) {
      return _SassLevel(
        badge: '🔥 BURNOUT',
        emoji: '😡',
        badgeColor: Colors.deepOrange,
        gradientColors: [Colors.orange.shade400, Colors.deepOrange],
        quote: _randomQuote([
          "Slow down champ, this isn't a spending marathon.",
          "Your wallet is sweating bullets right now.",
          'At this rate, dinner is "imagination soup."',
          "You're shopping like rent doesn't exist.",
          "Bro thinks money grows on trees 🌳",
        ]),
      );
    } else if (percentage >= 0.4) {
      return _SassLevel(
        badge: '⚖️ VIBING',
        emoji: '😐',
        badgeColor: Colors.amber.shade700,
        gradientColors: [Colors.amber.shade300, Colors.amber.shade600],
        quote: _randomQuote([
          "Not bad, not great. The financial equivalent of 'meh.'",
          "You're walking the tightrope between budget and chaos.",
          "Perfectly balanced, as all wallets should be.",
          "You're in the 'one more coffee won't hurt' zone. It will.",
          "Middle of the road. Like your last exam score.",
        ]),
      );
    } else if (percentage > 0.0) {
      return _SassLevel(
        badge: '💰 MONEYBAGS',
        emoji: '😁',
        badgeColor: const Color(0xFF00C853),
        gradientColors: [const Color(0xFF00E676), const Color(0xFF00C853)],
        quote: _randomQuote([
          "Look at you, actually having savings. Weird flex.",
          "Your wallet is doing a happy dance right now.",
          "Spending less than you earn? What a revolutionary concept!",
          "Today's vibe: financially responsible and dangerously boring.",
          "You're so under budget, even your bank is impressed.",
        ]),
      );
    } else {
      return _SassLevel(
        badge: '👑 UNTOUCHED',
        emoji: '🤑',
        badgeColor: const Color(0xFF00BFA5),
        gradientColors: [const Color(0xFF64FFDA), const Color(0xFF00BFA5)],
        quote: _randomQuote([
          "Zero spent? Are you even alive today?",
          "Your wallet is literally untouched. Museum-grade preservation.",
          "₹0 spent. Either it's too early or you're built different.",
          "No purchases? What is this, a simulation?",
          "Touch grass AND save money? Legend.",
        ]),
      );
    }
  }

  String _randomQuote(List<String> quotes) {
    // Use day-of-year as seed so it changes daily but stays consistent within a session
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }
}

class _SassLevel {
  final String badge;
  final String emoji;
  final Color badgeColor;
  final List<Color> gradientColors;
  final String quote;

  _SassLevel({
    required this.badge,
    required this.emoji,
    required this.badgeColor,
    required this.gradientColors,
    required this.quote,
  });
}
