import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import '../../dependency_injection.dart';
import '../../models/note_model.dart';
import '../components/note_edit.dart';

class NewNote extends StatefulWidget {
  final bool isPrivate;
  final DateTime? date;
  final String? initialTag;
  final VoidCallback? onSaveSuccessInMainMenu;

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
  bool isSaving = false;
  VoidCallback? _floatingActionButtonOnPressed;

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
        builder: (providerContext, child) {
          // Define FloatingActionButton callback inside the provider context
          _floatingActionButtonOnPressed = () async {
            if (isSaving) return;
            isSaving = true; // Set synchronously first
            setState(() {}); // Then trigger rebuild
            try {
              await _newNoteController.saveNote(
                providerContext, // Use the context that has access to the provider
                onSaveSuccessInMainMenu: widget.onSaveSuccessInMainMenu,
              );
            } finally {
              if (mounted) {
                isSaving = false; // Reset synchronously
                setState(() {}); // Then trigger rebuild
              }
            }
          };
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) =>
                _newNoteController.onPopHandler(providerContext, didPop),
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
              body: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: NoteEdit(
                  onSubmit: _floatingActionButtonOnPressed,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                mini: true,
                onPressed: _floatingActionButtonOnPressed,
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
