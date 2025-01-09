import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import 'LinkedNotes.dart';
import 'markdown_body_here.dart';

class NoteView extends StatelessWidget {
  final Note note;
  final List<Note>? linkedNotes;

  const NoteView({
    Key? key,
    required this.note,
    this.linkedNotes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (context, noteModel, child) {
        return CustomScrollView(
          slivers: [
            // Original note content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    note.isMarkdown
                        ? MarkdownBodyHere(data: note.content)
                        : Text(
                            note.formattedContent,
                            style: const TextStyle(fontSize: 16.0),
                          ),
                  ],
                ),
              ),
            ),

            // Linked notes section
            if (linkedNotes != null && linkedNotes!.isNotEmpty)
              LinkedNotes(linkedNotes: linkedNotes!, parentNote: note),
          ],
        );
      },
    );
  }
}
