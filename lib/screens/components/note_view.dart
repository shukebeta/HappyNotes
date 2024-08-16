// note_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import 'markdown_body_here.dart';

class NoteView extends StatelessWidget {
  final Note note;

  const NoteView({
    Key? key,
    required this.note,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: Consumer<NoteModel>(
                builder: (context, noteModel, child) {
                  return note.isMarkdown
                      ? MarkdownBodyHere(
                    data: note.content
                  )
                      : Text(
                    note.formattedContent,
                    style: const TextStyle(fontSize: 16.0),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
