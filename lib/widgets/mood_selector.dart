import 'package:flutter/material.dart';
import '../helpers/constants.dart';

class MoodSelector extends StatelessWidget {
  final Mood selectedMood;
  final Function(Mood) onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: Mood.values.map((mood) {
        final isSelected = mood == selectedMood;
        return GestureDetector(
          onTap: () => onMoodSelected(mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              _getMoodEmoji(mood),
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy: return '😃';
      case Mood.neutral: return '😐';
      case Mood.sad: return '😣';
    }
  }
}
