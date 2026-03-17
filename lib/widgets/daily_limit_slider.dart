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

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    double percentage = todaySpending / dailyLimit;
    if (percentage > 1.0) percentage = 1.0;
    
    String emoji = '😁';
    Color barColor = Colors.green;
    
    if (todaySpending >= dailyLimit) {
      emoji = '💀';
      barColor = Colors.red;
    } else if (percentage >= 0.7) {
      emoji = '😡';
      barColor = Colors.orange;
    } else if (percentage >= 0.4) {
      emoji = '😐';
      barColor = Colors.amber;
    }

    final sliderHeight = screenHeight * 0.18; 
    final sliderWidth = screenWidth * 0.04;
    final emojiSize = screenWidth * 0.07;

    return Container(
      margin: EdgeInsets.only(
        right: screenWidth * 0.04, 
        top: screenWidth * 0.04, 
        bottom: screenWidth * 0.04,
      ),
      height: sliderHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background Bar
          Container(
            width: sliderWidth,
            height: sliderHeight,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // Fill Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            width: sliderWidth,
            height: sliderHeight * percentage,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // Dragging Emoji Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            // Adjust position so emoji sits nicely on top of the bar
            bottom: (sliderHeight * percentage) - (emojiSize / 2),
            child: Text(
              emoji,
              style: TextStyle(fontSize: emojiSize),
            ),
          ),
        ],
      ),
    );
  }
}
