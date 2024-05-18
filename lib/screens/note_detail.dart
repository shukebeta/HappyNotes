import 'package:HappyNotes/services/notes_services.dart';
import 'package:flutter/material.dart';
import '../entities/note.dart';
import '../services/dialog_services.dart';
import '../utils/util.dart';

class NoteDetail extends StatefulWidget {
  final int noteId;

  const NoteDetail({super.key, required this.noteId});

  @override
  NoteDetailState createState() => NoteDetailState();
}

class NoteDetailState extends State<NoteDetail> {
  late Future<Note> _noteFuture;
  final TextEditingController _noteController = TextEditingController();
  bool _isPrivate = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _noteFuture = _fetchNote();
  }

  Future<Note> _fetchNote() async {
    final note = await NotesService.get(widget.noteId);
    _noteController.text = note.content;
    _isPrivate = note.isPrivate;
    return note;
  }

  Future<void> _saveNote() async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await NotesService.update(widget.noteId, _noteController.text, _isPrivate);
      setState(() {
        _isEditing = false;
        // No need to await _fetchNote() because FutureBuilder will handle the Future
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
      await NotesService.delete(widget.noteId);
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
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              var canDelete = await DialogService.showConfirmDialog(context) ?? false;
              if (canDelete) {
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
            final note = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isEditing
                      ? TextField(
                          controller: _noteController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Edit your note here...',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          note.content,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Text('Private Note'),
                      Switch(
                        value: _isEditing ? _isPrivate : note.isPrivate,
                        onChanged: _isEditing
                            ? (value) {
                                setState(() {
                                  _isPrivate = value;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No note found.'));
          }
        },
      ),
    );
  }
}
