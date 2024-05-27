import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../entities/note.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(int) onTap;
  final Function(int)? onDoubleTap;
  final Future<void> Function()? onRefresh;

  const NoteList({
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
      final dateKey = DateTime.fromMillisecondsSinceEpoch(note.createAt * 1000)
          .toString()
          .split(' ')[0];
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
                  if (entry.key < dayNotes.length - 1) const Divider(),
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
    return '- ${DateFormat('EEEE, MMM d, yyyy').format(date)} -';
  }
}
