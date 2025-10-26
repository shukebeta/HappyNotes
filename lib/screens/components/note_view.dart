import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../providers/linked_notes_provider.dart';
import 'package:happy_notes/screens/components/shared_fab.dart';
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
                            ? MarkdownBodyHere(data: widget.note.content, isPrivate: widget.note.isPrivate)
                            : Text(
                                widget.note.formattedContent,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: widget.note.isPrivate ? Colors.grey : Colors.black,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                // Linked notes section
                LinkedNotes(
                  linkedNotes: const [],
                  parentNote: widget.note,
                ),
              ],
            ),

            Positioned(
              right: 16,
              bottom: 16,
              child: Opacity(
                opacity: 0.75,
                child: SharedFab(
                  icon: Icons.edit_outlined,
                  isPrivate: widget.note.isPrivate,
                  busy: false,
                  mini: true,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final linkedNotesProvider = context.read<LinkedNotesProvider>();
                    final newNote = await navigator.push(
                      MaterialPageRoute(
                        builder: (context) => NewNote(
                          isPrivate: widget.note.isPrivate,
                          initialTag: '@${widget.note.id}',
                        ),
                      ),
                    );
                    if (newNote != null && mounted) {
                      linkedNotesProvider.addLinkedNote(widget.note.id, newNote);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
