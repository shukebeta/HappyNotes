import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import '../../dependency_injection.dart';
import '../../models/note_model.dart';
import '../../typedefs.dart';
import '../components/note_edit.dart';

class NewNote extends StatefulWidget {
  final bool isPrivate;
  final DateTime? date;
  final String? initialTag;
  // final SaveNoteCallback? onNoteSaved; // No longer needed
  final VoidCallback? onSaveSuccessInMainMenu; // Callback for MainMenu context

  const NewNote({
    Key? key,
    required this.isPrivate,
    this.initialTag,
    // this.onNoteSaved, // Removed
    this.date,
    this.onSaveSuccessInMainMenu, // Add to constructor
  }) : super(key: key);

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final _newNoteController = locator<NewNoteController>();
  late NoteModel noteModel;
  bool isSaving = false; // Add saving state flag

  @override
  void initState() {
    super.initState();
    noteModel = NoteModel();
    noteModel.isPrivate = widget.isPrivate;
    noteModel.isMarkdown = AppConfig.markdownIsEnabled;
    noteModel.content = '';
    noteModel.publishDateTime = widget.date != null
        ? DateFormat('yyyy-MM-dd').format(widget.date!)
        : '';
    if (widget.initialTag != null) {
      noteModel.initialContent = widget.initialTag!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => noteModel,
        builder: (context, child) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) =>
                _newNoteController.onPopHandler(context, didPop),
            child: Scaffold(
              appBar: AppBar(
                title: Consumer<NoteModel>(
                  builder: (context, noteModel, child) {
                    return Text(
                      _getNoteTitle(noteModel),
                      style: TextStyle(
                        color: noteModel.isPrivate
                            ? Colors.red
                            : Colors.green, // Change colors accordingly
                      ),
                    );
                  },
                ),
              ),
              body: const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: NoteEdit(),
              ),
              floatingActionButton: FloatingActionButton(
                mini: true,
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          // Pass the widget's callback to the controller
                          await _newNoteController.saveNote(
                            context,
                            onSaveSuccessInMainMenu: widget.onSaveSuccessInMainMenu,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => isSaving = false);
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(Icons.save),
              ),
            ),
          );
        });
  }

  String _getNoteTitle(NoteModel noteModel) {
    String privacyStatus = noteModel.isPrivate ? 'Private' : 'Public';
    String markdownIndicator = noteModel.isMarkdown ? ' with M↓' : '';
    String onDate = widget.date != null
        ? ' on ${DateFormat('dd-MMM-yyyy').format(widget.date!)}'
        : '';

    return '$privacyStatus note$markdownIndicator$onDate';
  }
}
