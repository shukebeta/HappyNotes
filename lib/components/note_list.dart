import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../entities/note.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(int) onTap;
  final Function(int)? onDoubleTap;
  final Future<void> Function()? onRefresh;
  final bool showDate;

  const NoteList({
    Key? key,
    required this.notes,
    required this.onTap,
    this.onDoubleTap,
    this.onRefresh,
    this.showDate = true,
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
              if (showDate)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(DateTime.parse(dateKey)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              // List of notes for that date with combined time and separator
              ...dayNotes.asMap().entries.map((entry) {
                final note = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CombinedTimeSeparator(note: note),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 1.0),
                      child: NoteListItem(
                        note: note,
                        onTap: () => onTap(note.id),
                        onDoubleTap: onDoubleTap != null
                            ? () => onDoubleTap!(note.id)
                            : null,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '- ${DateFormat('EEEE, MMM d, yyyy').format(date)} -';
  }

  String _formatTime(String createDate) {
    final dateTime = DateTime.parse(createDate);
    return DateFormat('HH:mm').format(dateTime);
  }
}

class CombinedTimeSeparator extends StatelessWidget {
  final Note note;

  const CombinedTimeSeparator({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            '- ${note.createTime} ${note.isPrivate ? '🔒' : ''}  ',
            style: const TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.shade200,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
