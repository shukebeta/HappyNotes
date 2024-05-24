import 'package:flutter/material.dart';
import '../../entities/note.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(int) onNoteTap;

  const NoteList({
    Key? key,
    required this.notes,
    required this.onNoteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteListItem(
          note: note,
          onTap: () => onNoteTap(note.id),
        );
      },
    );
  }
}
