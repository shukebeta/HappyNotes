import 'package:HappyNotes/services/notes_services.dart';
import 'package:flutter/material.dart';
import '../utils/util.dart';

class NewNote extends StatefulWidget {
  const NewNote({super.key});

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final TextEditingController _noteController = TextEditingController();
  Future<void> saveNote({required String note, required bool isPrivate}) async {
    final scaffoldContext =
    ScaffoldMessenger.of(context); // Capture the context
    final navigator = Navigator.of(context);
    try {
      final noteId = await NotesService.post(note, isPrivate);
      navigator.pop({'noteId': noteId});
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_noteController.text.isNotEmpty) {
          final shouldPop = await _showUnsavedChangesDialog(context);
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Note'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: TextField(
                    controller: _noteController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Write your note here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60), // Adjust the height as needed
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => saveNote(note: _noteController.text, isPrivate: false),
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  Future<bool?> _showUnsavedChangesDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved changes. Do you really want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
