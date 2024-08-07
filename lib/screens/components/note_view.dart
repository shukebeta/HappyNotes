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
        const SizedBox(height: 8.0),
        Row(
          children: [
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return Row(
                  children: [
                    const Text('Private'),
                    Switch(
                      value: noteModel.isPrivate,
                      onChanged: null, // Disable switch in view mode
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 24.0),
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return Row(
                  children: [
                    const Text('Markdown'),
                    Switch(
                      value: noteModel.isMarkdown,
                      onChanged: null, // Disable switch in view mode
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
