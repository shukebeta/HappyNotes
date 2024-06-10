import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../entities/note.dart';
import 'note_list_item.dart';

class MemoryList extends StatelessWidget {
  final List<Note> notes;
  final Function(int) onTap;
  final Function(int)? onDoubleTap;
  final Future<void> Function()? onRefresh;

  const MemoryList({
    Key? key,
    required this.notes,
    required this.onTap,
    this.onDoubleTap,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatDate(DateTime.parse(dateKey)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // List of notes for that date with dividers
              ...dayNotes
                  .asMap()
                  .entries
                  .map((entry) => Column(
                children: [
                  NoteListItem(
                    note: entry.value,
                    onTap: () => onTap(entry.value.id),
                    onDoubleTap: onDoubleTap != null
                        ? () => onDoubleTap!(entry.value.id)
                        : null,
                  ),
                  if (entry.key < dayNotes.length - 1) const Divider(
                    height: 1, // Adjust the height of the divider
                    thickness: 1,
                    indent: 16, // Indent to match ListTile padding
                    endIndent: 16, // Indent to match ListTile padding
                  ),
                ],
              ))
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    var suffix = ' - ${DateFormat('EEEE, MMM d, yyyy').format(date)}';
    if (difference.inDays >= 365) {
      final years = difference.inDays ~/ 365;
      return '$years year${years > 1 ? 's' : ''} ago$suffix';
    } else if (difference.inDays >= 30) {
      final months = difference.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago$suffix';
    } else if (difference.inDays >= 7) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago$suffix';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago$suffix';
    } else {
      return 'Today$suffix';
    }
  }
}
