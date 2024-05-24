import 'package:happy_notes/screens/new_note_controller.dart';
import 'package:flutter/material.dart';
import '../dependency_injection.dart';
import '../components/note_editor.dart';

class NewNote extends StatefulWidget {
  final bool isPrivate;

  const NewNote({super.key, required this.isPrivate});

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final newNoteController = locator<NewNoteController>();
  late FocusNode _noteFocusNode;
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.isPrivate;
    _noteFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noteFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => newNoteController.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Note'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: NoteEditor(
            controller: newNoteController.noteController,
            focusNode: _noteFocusNode,
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
          onPressed: () => newNoteController.saveNote(context, _isPrivate),
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    super.dispose();
  }
}
