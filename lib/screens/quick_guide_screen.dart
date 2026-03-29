import 'dart:math';
import 'package:flutter/material.dart';

class QuickGuideScreen extends StatefulWidget {
  const QuickGuideScreen({super.key});

  @override
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _bounceController;
  late AnimationController _fadeSlideController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  final List<_GuidePageData> _pages = [
    _GuidePageData(
      title: 'Welcome to NammaExpense! 👋',
      subtitle: 'Your pocket money bestie',
      description: 'Track every rupee, roast every bad decision,\nand flex your savings. Let\'s show you around!',
      icon: Icons.wallet,
      color: Color(0xFF6C63FF),
      doodleType: _DoodleType.stars,
    ),
    _GuidePageData(
      title: 'Add Expenses 💸',
      subtitle: '3 ways to add',
      description:
          '📝 Manual Add — Fill in details yourself\n⚡ Quick Add — Just amount + category\n🎤 Voice Add — Say "Spent 300 on groceries"\n\nTap the + button on the home screen!',
      icon: Icons.add_circle_outline,
      color: Color(0xFFFF6B6B),
      doodleType: _DoodleType.arrows,
    ),
    _GuidePageData(
      title: 'Swipe Actions 👆',
      subtitle: 'Left & Right magic',
      description:
          '👈 Swipe LEFT on any transaction → Delete it\n👉 Swipe RIGHT → Star / Unstar it\n\nWorks in Recent Transactions\nand All Transactions page!',
      icon: Icons.swipe,
      color: Color(0xFF4ECDC4),
      doodleType: _DoodleType.swipeArrows,
    ),
    _GuidePageData(
      title: 'Starred Favorites ⭐',
      subtitle: 'Mark what matters',
      description:
          'Starred expenses appear with a ⭐ icon\n\nTap the star icon in the Home top bar\nto see all your favorites!\n\nFilter by type, category, or sort by amount.',
      icon: Icons.star,
      color: Color(0xFFFFBE0B),
      doodleType: _DoodleType.stars,
    ),
    _GuidePageData(
      title: 'Dashboard & Insights 📊',
      subtitle: 'Know your spending',
      description:
          '📈 Stats tab shows weekly/monthly charts\n🔥 Brutal Insights roast your spending habits\n💬 Floating messages on dashboard\n\n(Toggle insights in Settings → Cruel Insights)',
      icon: Icons.insights,
      color: Color(0xFFFF006E),
      doodleType: _DoodleType.zigzag,
    ),
    _GuidePageData(
      title: 'Categories & Budget 🏷️',
      subtitle: 'Organize your money',
      description:
          '📂 Create custom categories in Settings\n💰 Set a Daily Spending Limit\n⚠️ Get warned when you overspend\n\nCategories auto-match with voice commands!',
      icon: Icons.category,
      color: Color(0xFF8338EC),
      doodleType: _DoodleType.circles,
    ),
    _GuidePageData(
      title: 'Backup & Restore 🛡️',
      subtitle: 'Never lose your data',
      description:
          '📤 Export → Saves a JSON backup file\n📥 Import → Restores from backup\n\n⚠️ Before app updates, always export!\nOld backups work with new versions.\n\nFind both in Settings → Data & Backup',
      icon: Icons.shield,
      color: Color(0xFF06D6A0),
      doodleType: _DoodleType.shield,
    ),
    _GuidePageData(
      title: 'Pro Tips 💡',
      subtitle: 'You\'re a pro now!',
      description:
          '🎤 Voice: "Spent 200 on chai for morning"\n🌙 Dark Mode: Settings → Appearance\n📅 Subscriptions: Track recurring bills\n🔄 Swipe right to star important spends\n\nYou\'re all set. Go crush it! 🚀',
      icon: Icons.lightbulb,
      color: Color(0xFFFB5607),
      doodleType: _DoodleType.lightbulb,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _bounceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _fadeSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playEntrance();
  }

  void _playEntrance() {
    _bounceController.reset();
    _fadeSlideController.reset();
    _bounceController.forward();
    _fadeSlideController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeSlideController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _playEntrance();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page counter
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.015),
                    decoration: BoxDecoration(
                      color: _pages[_currentPage].color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: TextStyle(
                        color: _pages[_currentPage].color,
                        fontWeight: FontWeight.bold,
                        fontSize: sw * 0.035,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Done' : 'Skip',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, sw, sh, isDark);
                },
              ),
            ),

            // Bottom: Dots + Next button
            Padding(
              padding: EdgeInsets.fromLTRB(sw * 0.06, 0, sw * 0.06, sh * 0.03),
              child: Row(
                children: [
                  // Dot indicators
                  Expanded(
                    child: Row(
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: sw * 0.015),
                          width: isActive ? sw * 0.06 : sw * 0.02,
                          height: sw * 0.02,
                          decoration: BoxDecoration(
                            color: isActive
                                ? _pages[_currentPage].color
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(sw * 0.01),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Next/Done button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _currentPage == _pages.length - 1 ? _pulseAnim.value : 1.0,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.06,
                          vertical: sw * 0.035,
                        ),
                        decoration: BoxDecoration(
                          color: _pages[_currentPage].color,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _pages[_currentPage].color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'Let\'s Go!' : 'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: sw * 0.04,
                              ),
                            ),
                            SizedBox(width: sw * 0.015),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.rocket_launch
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: sw * 0.05,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_GuidePageData page, double sw, double sh, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
      child: Column(
        children: [
          SizedBox(height: sh * 0.02),

          // Doodle illustration area
          ScaleTransition(
            scale: _bounceAnim,
            child: SizedBox(
              height: sh * 0.3,
              width: sw * 0.8,
              child: CustomPaint(
                painter: _DoodlePainter(
                  color: page.color,
                  type: page.doodleType,
                  isDark: isDark,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(sw * 0.06),
                      decoration: BoxDecoration(
                        color: page.color.withOpacity(isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: page.color.withOpacity(0.3),
                          width: 3,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: Icon(
                        page.icon,
                        size: sw * 0.15,
                        color: page.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: sh * 0.02),

          // Title
          SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: sw * 0.065,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                  height: 1.2,
                ),
              ),
            ),
          ),

          SizedBox(height: sh * 0.008),

          // Subtitle
          FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.015),
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                page.subtitle,
                style: TextStyle(
                  fontSize: sw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: page.color,
                ),
              ),
            ),
          ),

          SizedBox(height: sh * 0.025),

          // Description card
          SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(sw * 0.05),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: page.color.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: page.color.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Text(
                  page.description,
                  style: TextStyle(
                    fontSize: sw * 0.038,
                    height: 1.7,
                    color: isDark ? Colors.white70 : const Color(0xFF636E72),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: sh * 0.03),
        ],
      ),
    );
  }
}

// --- Data Model ---
class _GuidePageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final _DoodleType doodleType;

  const _GuidePageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.doodleType,
  });
}

enum _DoodleType { stars, arrows, swipeArrows, zigzag, circles, shield, lightbulb }

// --- Doodle Painter ---
class _DoodlePainter extends CustomPainter {
  final Color color;
  final _DoodleType type;
  final bool isDark;

  _DoodlePainter({required this.color, required this.type, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(isDark ? 0.15 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.06 : 0.04)
      ..style = PaintingStyle.fill;

    switch (type) {
      case _DoodleType.stars:
        _drawStars(canvas, size, paint, fillPaint);
        break;
      case _DoodleType.arrows:
        _drawArrows(canvas, size, paint);
        break;
      case _DoodleType.swipeArrows:
        _drawSwipeArrows(canvas, size, paint);
        break;
      case _DoodleType.zigzag:
        _drawZigzag(canvas, size, paint);
        break;
      case _DoodleType.circles:
        _drawCircles(canvas, size, paint, fillPaint);
        break;
      case _DoodleType.shield:
        _drawShield(canvas, size, paint, fillPaint);
        break;
      case _DoodleType.lightbulb:
        _drawLightbulbRays(canvas, size, paint);
        break;
    }
  }

  void _drawStars(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    // Scattered small stars
    final positions = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.1),
      Offset(size.width * 0.15, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.75),
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.45),
    ];
    final sizes = [12.0, 10.0, 8.0, 14.0, 6.0, 10.0];

    for (int i = 0; i < positions.length; i++) {
      _drawStar(canvas, positions[i], sizes[i], paint);
    }

    // Squiggly underline decoration at bottom
    final squigglePaint = Paint()
      ..color = color.withOpacity(isDark ? 0.12 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.92);
    for (double x = size.width * 0.2; x < size.width * 0.8; x += 20) {
      path.quadraticBezierTo(x + 5, size.height * 0.9, x + 10, size.height * 0.92);
      path.quadraticBezierTo(x + 15, size.height * 0.94, x + 20, size.height * 0.92);
    }
    canvas.drawPath(path, squigglePaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) - pi / 4;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final midAngle = angle + pi / 4;
      final mx = center.dx + cos(midAngle) * (radius * 0.4);
      final my = center.dy + sin(midAngle) * (radius * 0.4);
      path.lineTo(mx, my);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawArrows(Canvas canvas, Size size, Paint paint) {
    // Down arrow on left
    _drawCurvedArrow(canvas, Offset(size.width * 0.12, size.height * 0.25),
        Offset(size.width * 0.12, size.height * 0.55), paint);

    // Down arrow on right
    _drawCurvedArrow(canvas, Offset(size.width * 0.88, size.height * 0.2),
        Offset(size.width * 0.88, size.height * 0.5), paint);

    // Plus signs
    _drawPlus(canvas, Offset(size.width * 0.08, size.height * 0.12), 8, paint);
    _drawPlus(canvas, Offset(size.width * 0.92, size.height * 0.82), 10, paint);
    _drawPlus(canvas, Offset(size.width * 0.05, size.height * 0.7), 6, paint);

    // Dots
    final dotPaint = Paint()..color = color.withOpacity(isDark ? 0.2 : 0.15);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.9), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.9), 3, dotPaint);
  }

  void _drawCurvedArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(
      start.dx + 15, (start.dy + end.dy) / 2, end.dx, end.dy,
    );
    canvas.drawPath(path, paint);

    // Arrowhead
    canvas.drawLine(end, Offset(end.dx - 6, end.dy - 8), paint);
    canvas.drawLine(end, Offset(end.dx + 6, end.dy - 8), paint);
  }

  void _drawPlus(Canvas canvas, Offset center, double arm, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - arm, center.dy),
      Offset(center.dx + arm, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - arm),
      Offset(center.dx, center.dy + arm),
      paint,
    );
  }

  void _drawSwipeArrows(Canvas canvas, Size size, Paint paint) {
    final leftPaint = Paint()
      ..color = Colors.red.withOpacity(isDark ? 0.2 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rightPaint = Paint()
      ..color = Colors.amber.withOpacity(isDark ? 0.25 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Left swipe arrow (delete)
    final leftStart = Offset(size.width * 0.35, size.height * 0.2);
    final leftEnd = Offset(size.width * 0.08, size.height * 0.2);
    canvas.drawLine(leftStart, leftEnd, leftPaint);
    canvas.drawLine(leftEnd, Offset(leftEnd.dx + 10, leftEnd.dy - 8), leftPaint);
    canvas.drawLine(leftEnd, Offset(leftEnd.dx + 10, leftEnd.dy + 8), leftPaint);

    // "Delete" text doodle
    _drawCrossmark(canvas, Offset(size.width * 0.08, size.height * 0.3), 8, leftPaint);

    // Right swipe arrow (star)
    final rightStart = Offset(size.width * 0.65, size.height * 0.78);
    final rightEnd = Offset(size.width * 0.92, size.height * 0.78);
    canvas.drawLine(rightStart, rightEnd, rightPaint);
    canvas.drawLine(rightEnd, Offset(rightEnd.dx - 10, rightEnd.dy - 8), rightPaint);
    canvas.drawLine(rightEnd, Offset(rightEnd.dx - 10, rightEnd.dy + 8), rightPaint);

    // Star doodle
    _drawStar(canvas, Offset(size.width * 0.92, size.height * 0.67), 10, rightPaint);

    // Squiggly lines
    _drawSquiggly(canvas, size.height * 0.48, size, paint);
  }

  void _drawCrossmark(Canvas canvas, Offset center, double arm, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - arm, center.dy - arm),
      Offset(center.dx + arm, center.dy + arm),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + arm, center.dy - arm),
      Offset(center.dx - arm, center.dy + arm),
      paint,
    );
  }

  void _drawSquiggly(Canvas canvas, double y, Size size, Paint paint) {
    final path = Path();
    path.moveTo(size.width * 0.1, y);
    for (double x = size.width * 0.1; x < size.width * 0.9; x += 24) {
      path.quadraticBezierTo(x + 6, y - 6, x + 12, y);
      path.quadraticBezierTo(x + 18, y + 6, x + 24, y);
    }
    canvas.drawPath(path, paint);
  }

  void _drawZigzag(Canvas canvas, Size size, Paint paint) {
    // Zigzag lines top
    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.15);
    for (double x = size.width * 0.05; x < size.width * 0.4; x += 16) {
      path.lineTo(x + 8, size.height * 0.1);
      path.lineTo(x + 16, size.height * 0.15);
    }
    canvas.drawPath(path, paint);

    // Bar chart doodle right side
    final barPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.12 : 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.78, size.height * 0.55, size.width * 0.05, size.height * 0.25),
        const Radius.circular(3),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.85, size.height * 0.45, size.width * 0.05, size.height * 0.35),
        const Radius.circular(3),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.92, size.height * 0.6, size.width * 0.05, size.height * 0.2),
        const Radius.circular(3),
      ),
      barPaint,
    );

    // Dots
    _drawPlus(canvas, Offset(size.width * 0.9, size.height * 0.15), 6, paint);
    _drawPlus(canvas, Offset(size.width * 0.08, size.height * 0.75), 5, paint);
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    // Doodle circles scattered
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 18, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.15), 12, paint);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.75), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.8), 15, paint);

    // Dotted circle center-ish
    final dottedPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.1 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = (i * pi * 2) / 12;
      final start = Offset(
        size.width * 0.5 + cos(angle) * size.width * 0.38,
        size.height * 0.5 + sin(angle) * size.width * 0.38,
      );
      canvas.drawCircle(start, 3, dottedPaint);
    }

    // Grid dots
    _drawPlus(canvas, Offset(size.width * 0.15, size.height * 0.5), 5, paint);
    _drawPlus(canvas, Offset(size.width * 0.88, size.height * 0.5), 5, paint);
  }

  void _drawShield(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    // Shield outline at corners
    final shieldPath = Path();
    final sx = size.width * 0.08;
    final sy = size.height * 0.15;
    shieldPath.moveTo(sx, sy + 15);
    shieldPath.lineTo(sx, sy + 5);
    shieldPath.quadraticBezierTo(sx, sy, sx + 5, sy);
    shieldPath.lineTo(sx + 18, sy);
    shieldPath.quadraticBezierTo(sx + 23, sy, sx + 23, sy + 5);
    shieldPath.lineTo(sx + 23, sy + 18);
    shieldPath.quadraticBezierTo(sx + 11, sy + 30, sx, sy + 15);
    canvas.drawPath(shieldPath, paint);

    // Checkmark inside shield
    canvas.drawLine(Offset(sx + 7, sy + 14), Offset(sx + 11, sy + 18), paint);
    canvas.drawLine(Offset(sx + 11, sy + 18), Offset(sx + 17, sy + 9), paint);

    // Corner decorations
    _drawPlus(canvas, Offset(size.width * 0.9, size.height * 0.12), 7, paint);
    _drawPlus(canvas, Offset(size.width * 0.12, size.height * 0.85), 5, paint);

    // Arrows circling (data flow)
    final arrowPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.12 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final arcPath = Path();
    arcPath.addArc(
      Rect.fromCenter(center: Offset(size.width * 0.88, size.height * 0.7), width: 30, height: 30),
      0,
      pi * 1.5,
    );
    canvas.drawPath(arcPath, arrowPaint);
  }

  void _drawLightbulbRays(Canvas canvas, Size size, Paint paint) {
    // Rays emanating from center
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final rayPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.1 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi * 2) / 8;
      final start = Offset(
        center.dx + cos(angle) * size.width * 0.25,
        center.dy + sin(angle) * size.width * 0.25,
      );
      final end = Offset(
        center.dx + cos(angle) * size.width * 0.32,
        center.dy + sin(angle) * size.width * 0.32,
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Little sparkles
    _drawStar(canvas, Offset(size.width * 0.12, size.height * 0.15), 8, paint);
    _drawStar(canvas, Offset(size.width * 0.88, size.height * 0.2), 6, paint);
    _drawStar(canvas, Offset(size.width * 0.1, size.height * 0.8), 7, paint);
    _drawStar(canvas, Offset(size.width * 0.92, size.height * 0.85), 9, paint);

    // Squiggly bottom decoration
    _drawSquiggly(canvas, size.height * 0.92, size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
