import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import '../../dependency_injection.dart';
import '../../models/note_model.dart';
import '../../models/save_note_result.dart';
import '../../providers/notes_provider.dart';
import '../../services/dialog_services.dart';
import '../../utils/util.dart';
import '../components/note_edit.dart';
import 'package:happy_notes/screens/components/shared_fab.dart';
import '../components/hour_picker_dialog.dart';

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
    noteModel.publishDateTime = widget.date != null ? DateFormat('yyyy-MM-dd').format(widget.date!) : '';
    if (widget.initialTag != null) {
      noteModel.initialContent = widget.initialTag!;
    }
  }

  /// Handle SaveNoteResult from controller
  void _handleSaveResultSync(
    ScaffoldMessengerState scaffoldMessenger,
    NavigatorState navigator,
    SaveNoteResult result,
    VoidCallback? onSaveSuccessInMainMenu,
  ) {
    switch (result) {
      case SaveNoteSuccess success:
        switch (success.action) {
          case SaveNoteAction.executeCallback:
            onSaveSuccessInMainMenu?.call();
            break;
          case SaveNoteAction.popWithNote:
            navigator.pop(success.savedNote);
            break;
        }
        break;
      case SaveNoteValidationError validationError:
        Util.showInfo(scaffoldMessenger, validationError.message);
        break;
      case SaveNoteServiceError serviceError:
        Util.showError(scaffoldMessenger, serviceError.message);
        break;
    }
  }

  /// Handle PopHandlerResult from controller
  Future<void> _handlePopResult(
    BuildContext context,
    PopHandlerResult result,
    NoteModel noteModel,
  ) async {
    switch (result) {
      case PopHandlerAllow():
        noteModel.initialContent = '';
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
        break;
      case PopHandlerShowDialog():
        final shouldPop = await DialogService.showUnsavedChangesDialog(context) ?? false;
        if (shouldPop && context.mounted) {
          noteModel.initialContent = '';
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        }
        break;
      case PopHandlerPrevent():
        // Do nothing - pop is already prevented
        break;
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
              final noteModel = providerContext.read<NoteModel>();
              final notesProvider = providerContext.read<NotesProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);


              // Check if we need hour selection for non-today dates
              if (widget.date != null && !DateUtils.isSameDay(widget.date!, DateTime.now())) {
                final selectedHour = await HourPickerDialog.show(context, widget.date!);
                if (selectedHour == null) {
                  // User cancelled, stop saving
                  isSaving = false;
                  setState(() {});
                  return;
                }
                
                // Update noteModel with complete timestamp
                final now = DateTime.now();
                final selectedDateTime = DateTime(
                  widget.date!.year,
                  widget.date!.month,
                  widget.date!.day,
                  selectedHour,
                  now.minute,
                  now.second,
                );
                noteModel.publishDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDateTime);
              }
              final result = await _newNoteController.saveNoteAsync(
                noteModel,
                notesProvider,
                useCallback: widget.onSaveSuccessInMainMenu != null,
              );

              if (mounted) {
                _handleSaveResultSync(
                  scaffoldMessenger,
                  navigator,
                  result,
                  widget.onSaveSuccessInMainMenu,
                );
              }
            } finally {
              if (mounted) {
                isSaving = false; // Reset synchronously
                setState(() {}); // Then trigger rebuild
              }
            }
          };
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              final noteModel = providerContext.read<NoteModel>();
              final popResult = _newNoteController.handlePopAsync(noteModel, didPop);
              await _handlePopResult(context, popResult, noteModel);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Consumer<NoteModel>(
                  builder: (context, noteModel, child) {
                    return Text(
                      _getNoteTitle(noteModel),
                      style: TextStyle(
                        color: noteModel.isPrivate ? Colors.red : Colors.green, // Change colors accordingly
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
              floatingActionButton: Opacity(
                opacity: 0.85,
                child: Consumer<NoteModel>(
                  builder: (context, nm, child) {
                    return SharedFab(
                      icon: isSaving ? Icons.hourglass_top : Icons.save,
                      isPrivate: nm.isPrivate,
                      busy: isSaving,
                      mini: true,
                      onPressed: _floatingActionButtonOnPressed,
                      heroTag: 'new_note_save_fab',
                    );
                  },
                ),
              ),
            ),
          );
        });
  }

  String _getNoteTitle(NoteModel noteModel) {
    String privacyStatus = noteModel.isPrivate ? 'Private' : 'Public';
    String markdownIndicator = noteModel.isMarkdown ? ' with M↓' : '';
    String onDate = widget.date != null ? ' on ${DateFormat('dd-MMM-yyyy').format(widget.date!)}' : '';

    return '$privacyStatus note$markdownIndicator$onDate';
  }
}
