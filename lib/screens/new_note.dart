import 'package:happy_notes/screens/new_note_controller.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/typedefs.dart';
import '../dependency_injection.dart';
import '../components/note_editor.dart';

class NewNote extends StatefulWidget {
  final bool isPrivate;
  final SaveNoteCallback? onNoteSaved;

  const NewNote(
      {super.key, required this.isPrivate, required this.onNoteSaved});

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final _newNoteController = locator<NewNoteController>();
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.isPrivate;

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
      onPopInvoked: (didPop) =>
          _newNoteController.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isPrivate ? 'Private Note' : 'Public Note'),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 4.0),
          child: NoteEditor(
            controller: _newNoteController.noteController,
            focusNode: _newNoteController.noteFocusNode,
            isEditing: true,
            isPrivate: _isPrivate,
            onPrivateChanged: (value) {
              setState(() {
                _isPrivate = value;
              });
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _newNoteController.saveNote(
              context, _isPrivate, widget.onNoteSaved),
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
