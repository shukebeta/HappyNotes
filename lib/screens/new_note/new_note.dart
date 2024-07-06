import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import '../../dependency_injection.dart';
import '../../models/note_model.dart';
import '../../typedefs.dart';
import '../components/note_editor.dart';

class NewNote extends StatefulWidget {
  final bool initialIsPrivate;
  final bool initialIsMarkdown;
  final SaveNoteCallback? onNoteSaved;

  const NewNote({Key? key, required this.initialIsMarkdown, required this.initialIsPrivate, this.onNoteSaved})
      : super(key: key);

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final _newNoteController = locator<NewNoteController>();

  @override
  void initState() {
    super.initState();
    final noteModel = context.read<NoteModel>();
    noteModel.isPrivate = widget.initialIsPrivate;
    noteModel.isMarkdown = widget.initialIsMarkdown;
    setFocus(true);
  }

  void setFocus(bool targetFocusStatus) {
    if (targetFocusStatus) {
      _newNoteController.noteFocusNode.requestFocus();
    } else {
      _newNoteController.noteFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _newNoteController.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<NoteModel>(
            builder: (context, noteModel, child) {
              return Text(noteModel.isPrivate ? 'Private Note' : 'Public Note');
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 4.0),
          child: NoteEditor(
            controller: _newNoteController.noteController,
            focusNode: _newNoteController.noteFocusNode,
            isEditing: true,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final noteModel = context.read<NoteModel>();
            _newNoteController.saveNote(
              context,
              noteModel.isPrivate,
              noteModel.isMarkdown,
              widget.onNoteSaved,
            );
          },
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }
}
