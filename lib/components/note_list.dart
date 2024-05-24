import 'package:flutter/material.dart';
import '../../entities/note.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(int) onTap;
  Function(int)? onDoubleTap;

  NoteList({
    Key? key,
    required this.notes,
    required this.onTap,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteListItem(
          note: note,
          onTap: () => onTap(note.id),
          onDoubleTap: onDoubleTap != null  ? () => onDoubleTap!(note.id) : null,
        );
      },
    );
  }
}
