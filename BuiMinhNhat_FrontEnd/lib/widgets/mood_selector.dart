import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final String selectedMood;
  final ValueChanged<String> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  static const List<Map<String, String>> moods = [
    {'key': 'Energetic', 'emoji': '⚡', 'label': 'Tràn đầy năng lượng'},
    {'key': 'Happy', 'emoji': '😊', 'label': 'Vui vẻ / Hào hứng'},
    {'key': 'Neutral', 'emoji': '😐', 'label': 'Bình thường'},
    {'key': 'Tired', 'emoji': '😴', 'label': 'Hơi mệt mỏi'},
    {'key': 'Stressed', 'emoji': '🤯', 'label': 'Căng thẳng'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn trạng thái cảm xúc / năng lượng khi bắt đầu ca:',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: moods.map((item) {
            final isSelected = selectedMood == item['key'];
            return ChoiceChip(
              showCheckmark: false,
              avatar: Text(item['emoji']!, style: const TextStyle(fontSize: 16)),
              label: Text(
                item['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.amber.shade100,
              backgroundColor: Colors.grey.shade50,
              side: BorderSide(
                color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
              onSelected: (selected) {
                if (selected) {
                  onMoodSelected(item['key']!);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
