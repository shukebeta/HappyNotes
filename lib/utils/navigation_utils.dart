import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';

import '../entities/note.dart';
import '../screens/tag_notes/tag_notes.dart';

class NoteEventHandler {
  static Future<void> onTagTap(BuildContext context, Note note, String tag) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => tag.startsWith('@') ? NoteDetail(noteId: int.parse(tag.substring(1))) : TagNotes(tag: tag, myNotesOnly: true),
      ),
    );
  }
}
