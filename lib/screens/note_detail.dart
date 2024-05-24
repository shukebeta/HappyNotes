import 'package:happy_notes/services/notes_services.dart';
import 'package:flutter/material.dart';
import '../dependency_injection.dart';
import '../entities/note.dart';
import '../services/dialog_services.dart';
import '../utils/util.dart';
import '../components/note_editor.dart';

class NoteDetail extends StatefulWidget {
  final int noteId;

  const NoteDetail({super.key, required this.noteId});

  @override
  NoteDetailState createState() => NoteDetailState();
}

class NoteDetailState extends State<NoteDetail> {
  late Future<Note> _noteFuture;
  final TextEditingController _noteController = TextEditingController();
  final _notesService = locator<NotesService>();
  bool _isPrivate = false;
  bool _isEditing = false;
  late FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _noteFuture = _fetchNote();
    _noteFocusNode = FocusNode();
  }

  Future<Note> _fetchNote() async {
    final note = await _notesService.get(widget.noteId);
    _noteController.text = note.content;
    _isPrivate = note.isPrivate;
    return note;
  }

  Future<void> _saveNote() async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _notesService.update(widget.noteId, _noteController.text, _isPrivate);
      setState(() {
        _isEditing = false;
        _noteFuture = _fetchNote(); // Refresh note data
      });
      Util.showInfo(scaffoldContext, 'Note successfully updated.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  Future<void> _deleteNote() async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _notesService.delete(widget.noteId);
      navigator.pop(); // Go back to the previous screen
      Util.showInfo(scaffoldContext, 'Note successfully deleted.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveNote,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _noteFocusNode.requestFocus();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              var sure = await DialogService.showConfirmDialog(context, title: 'Delete note', text: 'Each note has its story, are you sure you want to delete this one?') ?? false;
              if (sure) {
                _deleteNote();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Note>(
        future: _noteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: NoteEditor(
                controller: _noteController,
                focusNode: _noteFocusNode,
                isEditing: _isEditing,
                isPrivate: _isEditing ? _isPrivate : snapshot.data!.isPrivate,
                onPrivateChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
              ),
            );
          } else {
            return const Center(child: Text('No note found.'));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    super.dispose();
  }
}
