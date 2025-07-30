import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../new_note/new_note.dart';
import 'linked_notes.dart';
import 'markdown_body_here.dart';

class NoteView extends StatefulWidget {
  final Note note;

  const NoteView({
    Key? key,
    required this.note,
  }) : super(key: key);

  @override
  NoteViewState createState() => NoteViewState();
}

class NoteViewState extends State<NoteView> {
  final GlobalKey<LinkedNotesState> _linkedNotesKey = GlobalKey<LinkedNotesState>();


  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (context, noteModel, child) {
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Original note content
                SliverToBoxAdapter(
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.note.isMarkdown
                            ? MarkdownBodyHere(
                                data: widget.note.content,
                                isPrivate: widget.note.isPrivate)
                            : Text(
                                widget.note.formattedContent,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: widget.note.isPrivate
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                // Linked notes section
                LinkedNotes(
                  key: _linkedNotesKey,
                  linkedNotes: const [],
                  parentNote: widget.note,
                ),
              ],
            ),

            // Add Note Button
            Positioned(
              right: 0,
              bottom: 16,
              child: Opacity(
                opacity: 0.5,
                child: FloatingActionButton(
                  onPressed: () async {
                    final newNoteSaved = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewNote(
                          isPrivate: widget.note.isPrivate,
                          initialTag: '@${widget.note.id}',
                        ),
                      ),
                    );
                    if (newNoteSaved ?? false) {
                      _linkedNotesKey.currentState?.refreshNotes();
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
