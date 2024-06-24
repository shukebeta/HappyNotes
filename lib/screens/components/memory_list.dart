import 'package:flutter/material.dart';
import '../../entities/note.dart';
import '../../screens/memories/memories_on_day.dart';
import 'memory_list_item.dart';

class MemoryList extends StatelessWidget {
  final List<Note> notes;
  final Future<void> Function()? onRefresh;

  const MemoryList({
    Key? key,
    required this.notes,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group notes by date
    final notesByDate = <String, List<Note>>{};
    for (var note in notes) {
      final dateKey = note.createDate!;
      notesByDate[dateKey] = notesByDate[dateKey] ?? [];
      notesByDate[dateKey]!.add(note);
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        itemCount: notesByDate.keys.length,
        itemBuilder: (context, index) {
          final dateKey = notesByDate.keys.elementAt(index);
          final dayNotes = notesByDate[dateKey]!;
          final date = DateTime.parse(dateKey);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              GestureDetector(
                onTap: () => _navigateToMemoriesOnDay(context, date),
                child: Container(
                  color: const Color(0xFFEBDDFF), // Light purple background
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
              // List of notes for that date with dividers
              ...dayNotes.asMap().entries.map((entry) {
                final note = entry.value;
                return GestureDetector(
                  onTap: () => _navigateToMemoriesOnDay(context, date),
                  child: Column(
                    children: [
                      MemoryListItem(
                        note: note,
                        onTap: () => _navigateToMemoriesOnDay(context, date),
                      ),
                      if (entry.key < dayNotes.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  void _navigateToMemoriesOnDay(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoriesOnDay(date: date),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays >= 365) {
      final years = difference.inDays ~/ 365;
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays >= 30) {
      final months = difference.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays >= 7) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}
