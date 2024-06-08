import 'package:flutter/material.dart';
import '../dependency_injection.dart';
import '../entities/note.dart';
import '../services/dialog_services.dart';
import '../components/note_editor.dart';
import '../services/notes_services.dart';
import 'note_detail_controller.dart';

// ignore: must_be_immutable
class NoteDetail extends StatefulWidget {
  final int noteId;
  bool? enterEditing;

  NoteDetail({super.key, required this.noteId, this.enterEditing});

  @override
  NoteDetailState createState() => NoteDetailState();
}

class NoteDetailState extends State<NoteDetail> {
  late Future<Note> _noteFuture;
  late NoteDetailController _controller;
  late Note _note;

  @override
  void initState() {
    super.initState();
    _controller = NoteDetailController(notesService: locator<NotesService>());
    _controller.isEditing = widget.enterEditing ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.isEditing) _controller.noteFocusNode.requestFocus();
    });
    _noteFuture = _controller.fetchNote(widget.noteId);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _controller.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Note Details'),
          actions: [
            if (_controller.isEditing)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () =>
                    _controller.saveNote(context, widget.noteId, () {
                  setState(() {
                    _noteFuture = _controller.fetchNote(widget.noteId);
                  });
                }),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _controller.isEditing = true;
                    _controller.noteController.text = _note.content;
                    _controller.noteFocusNode.requestFocus();
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                var sure = await DialogService.showConfirmDialog(
                      context,
                      title: 'Delete note',
                      text:
                          'Each note is a story, are you sure you want to delete it?',
                    ) ??
                    false;
                if (sure) {
                  _controller.deleteNote(context, widget.noteId, () {
                    setState(() {
                      _noteFuture = _controller.fetchNote(widget.noteId);
                    });
                  });
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
              _note = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: NoteEditor(
                  controller: _controller.noteController,
                  focusNode: _controller.noteFocusNode,
                  isEditing: _controller.isEditing,
                  isPrivate: _controller.isEditing
                      ? _controller.isPrivate
                      : snapshot.data!.isPrivate,
                  onPrivateChanged: (value) {
                    setState(() {
                      _controller.isPrivate = value;
                    });
                  },
                ),
              );
            } else {
              return const Center(child: Text('No note found.'));
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
