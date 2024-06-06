import 'package:happy_notes/screens/new_note_controller.dart';
import 'package:flutter/material.dart';
import '../dependency_injection.dart';
import '../components/note_editor.dart';
class NewNote extends StatefulWidget {
  final bool isPrivate;
  final VoidCallback? onNoteSaved;
  const NewNote({super.key, required this.isPrivate, required this.onNoteSaved});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newNoteController.noteFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _newNoteController.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Note'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
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
          onPressed: () => _newNoteController.saveNote(context, _isPrivate, widget.onNoteSaved),
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newNoteController.dispose();
    _newNoteController.noteFocusNode.dispose();
    super.dispose();
  }
}
