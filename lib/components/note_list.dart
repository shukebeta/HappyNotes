import 'package:flutter/material.dart';
import '../../entities/note.dart';
import 'note_list_item.dart';
import 'package:intl/intl.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(int) onTap;
  final Function(int)? onDoubleTap;

  NoteList({
    Key? key,
    required this.notes,
    required this.onTap,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group notes by date
    final notesByDate = <String, List<Note>>{};
    for (var note in notes) {
      final dateKey = DateTime.fromMillisecondsSinceEpoch(note.createAt * 1000).toString().split(' ')[0];
      notesByDate[dateKey] = notesByDate[dateKey] ?? [];
      notesByDate[dateKey]!.add(note);
    }

    return ListView.builder(
      itemCount: notesByDate.keys.length,
      itemBuilder: (context, index) {
        final dateKey = notesByDate.keys.elementAt(index);
        final dayNotes = notesByDate[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Align(
              alignment: Alignment.center,
              child:Text(
                _formatDate(DateTime.parse(dateKey)),
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                ),
              ),
            ),
            ),
            // List of notes for that date
            ...dayNotes.map((note) => NoteListItem(
              note: note,
              onTap: () => onTap(note.id),
              onDoubleTap: onDoubleTap != null ? () => onDoubleTap!(note.id) : null,
            )).toList(),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '- ${DateFormat('EEEE, MMM d, yyyy').format(date)} -';
  }
}
