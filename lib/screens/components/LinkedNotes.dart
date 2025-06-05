import 'package:flutter/material.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../note_detail/note_detail.dart';
import '../components/note_list/note-list-item.dart';
import '../components/note_list/note-list.dart';
import '../../services/notes_services.dart';
import '../../dependency_injection.dart';
import '../../models/notes_result.dart';

class LinkedNotes extends StatefulWidget {
  final List<Note> linkedNotes;
  final Note parentNote;

  const LinkedNotes({
    Key? key,
    required this.linkedNotes,
    required this.parentNote,
  }) : super(key: key);

  @override
  _LinkedNotesState createState() => _LinkedNotesState();
}

class _LinkedNotesState extends State<LinkedNotes> {
  late List<Note> _linkedNotes;
  final NotesService _notesService = locator<NotesService>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _linkedNotes = List<Note>.from(widget.linkedNotes); // Create a copy of the list
  }

  Future<void> _refreshNotes() async {
    if (_isLoading) return; // Prevent multiple refreshes at once

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all linked notes in one go
      NotesResult result = await _notesService.getLinkedNotes(widget.parentNote.id);
      setState(() {
        _linkedNotes = result.notes;
      });
    } catch (error) {
      // Handle error if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_linkedNotes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildListDelegate([
        // "Linked Notes" header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Linked Notes",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // Linked notes list
        ..._linkedNotes.map((note) => NoteListItem(
          note: note,
          callbacks: ListItemCallbacks<Note>(
            onTap: (note) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetail(note: note),
              ),
            ),
            onDoubleTap: (note) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetail(
                  note: note,
                  enterEditing: widget.parentNote.userId == UserSession().id,
                  onNoteSaved: _refreshNotes, // Pass the refresh callback
                ),
              ),
            ),
          ),
          onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
          config: const ListItemConfig(
            showDate: true,
            showAuthor: true, // Show author for linked notes
            showRestoreButton: false,
            enableDismiss: false,
          ),
        )).toList(),
      ]),
    );
  }
}
