import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../dependency_injection.dart';
import '../../services/notes_services.dart';
import '../new_note/new_note.dart';
import 'LinkedNotes.dart';
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
  List<Note>? linkedNotes;
  final NotesService _notesService = locator<NotesService>();
  bool isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadLinkedNotes();
    }
  }

  Future<void> _loadLinkedNotes() async {
    try {
      final notes = await _notesService.getLinkedNotes(widget.note.id);
      setState(() {
        isLoading = false;
        linkedNotes = notes.notes;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        linkedNotes = []; // Set to empty list on error
      });
    }
  }

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

                // Linked notes section with loading state
                if (isLoading)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (linkedNotes != null && linkedNotes!.isNotEmpty)
                  LinkedNotes(
                      linkedNotes: linkedNotes!, parentNote: widget.note),
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
                    final navigator = Navigator.of(context);
                    final newNote = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewNote(
                          isPrivate: widget.note.isPrivate,
                          initialTag: '@${widget.note.id}',
                          // onNoteSaved removed
                        ),
                      ),
                    );
                    if (newNote != null) {
                      await _loadLinkedNotes();
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
