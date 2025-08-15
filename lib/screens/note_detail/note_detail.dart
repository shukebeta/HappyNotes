import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/note_edit.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/dialog_services.dart';
import '../../services/notes_services.dart';
import '../account/user_session.dart';
import '../components/note_view.dart';
import '../trash_bin/trash_bin_page.dart';
import '../../providers/notes_provider.dart';
import '../../utils/util.dart';
import '../../utils/app_logger_interface.dart';
import '../../dependency_injection.dart';
import 'package:get_it/get_it.dart';

class NoteDetail extends StatefulWidget {
  final Note? note;
  final int? noteId;
  final bool? enterEditing;
  final void Function(Note)? onNoteSaved; // Callback when note is saved
  final bool fromDetailPage; // Flag to indicate if coming from detail page

  const NoteDetail({
    super.key,
    this.note,
    this.noteId,
    this.enterEditing,
    this.onNoteSaved,
    this.fromDetailPage = false,
  });

  @override
  NoteDetailState createState() => NoteDetailState();
}

class NoteDetailState extends State<NoteDetail> with RouteAware {
  Note? note;
  List<Note>? linkedNotes = [];
  bool _initialized = false;
  bool _editingFromDetailPage = false; // Track if editing from detail page
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isLoading = false;
  VoidCallback? _saveNoteHandler;
  Note? _originalNote;

  @override
  void initState() {
    _isEditing = widget.enterEditing ?? false;
    note = widget.note;
    _editingFromDetailPage = widget.fromDetailPage; // Initialize from widget
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (!_initialized) {
      await _fetchNote();
      _initialized = true;
      setState(() {});
    }
  }

  Future<void> _fetchNote() async {
    setState(() {
      _isLoading = true;
    });

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    final fetchedNote = await notesProvider.getNote(
      note?.id ?? widget.noteId!,
    );

    if (fetchedNote != null) {
      _originalNote = fetchedNote;
      note = fetchedNote;
    } else if (mounted) {
      Util.showError(ScaffoldMessenger.of(context), 'Failed to load note');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _enterEditingMode() async {
    if (note?.userId != UserSession().id) return;
    if (!_isEditing) {
      _isEditing = true;
      // When entering editing mode from the detail page, set _editingFromDetailPage to true
      setState(() {
        _editingFromDetailPage = true;
      });
    }
    setState(() {});
  }


  @override
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _saveNote(NoteModel noteModel) async {
    final logger = GetIt.instance<AppLoggerInterface>();
    final noteId = note?.id ?? widget.noteId!;
    
    logger.d('NoteDetail._saveNote called: noteId=$noteId, content length=${noteModel.content.length}, fromDetailPage=$_editingFromDetailPage');
    
    if (_isSaving) {
      logger.d('NoteDetail._saveNote already saving, returning');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final notesService = locator<NotesService>();

    try {
      logger.d('NoteDetail._saveNote calling NotesService.update for noteId=$noteId');
      final updatedNote = await notesService.update(
        noteId,
        noteModel.content,
        noteModel.isPrivate,
        noteModel.isMarkdown,
      );

      logger.d('NoteDetail._saveNote success: updated note ${updatedNote.id}');
      
      // Update local note for UI consistency
      note = updatedNote;
      widget.onNoteSaved?.call(updatedNote);

      if (_editingFromDetailPage) {
        // Stay in view mode when editing from detail page
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        if (mounted) {
          Util.showInfo(scaffoldMessenger, 'Note successfully updated.');
        }
      } else {
        // Return updated note to calling page
        if (mounted) {
          Util.showInfo(scaffoldMessenger, 'Note successfully updated.');
        }
        navigator.pop(updatedNote);
      }
    } catch (e) {
      logger.e('NoteDetail._saveNote error: $e for noteId=$noteId');
      
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        Util.showError(scaffoldMessenger, 'Failed to update note: ${e.toString()}');
      }
      // Don't pop on error - let user retry
    }
  }

  Future<void> _deleteNote() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await notesProvider.deleteNote(note?.id ?? widget.noteId!);

    if (result.isSuccess) {
      navigator.pop(true);
      if (mounted) {
        Util.showInfo(scaffoldMessenger, 'Note successfully deleted.');
      }
    } else if (mounted) {
      Util.showError(scaffoldMessenger, result.errorMessage!);
    }
  }

  Future<void> _undeleteNote() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await notesProvider.undeleteNote(note?.id ?? widget.noteId!);

    if (success) {
      navigator.pop(true);
      if (mounted) {
        Util.showInfo(scaffoldMessenger, 'Note successfully undeleted.');
      }
    } else if (mounted) {
      Util.showError(scaffoldMessenger, 'Failed to undelete note');
    }
  }

  Future<bool> _onPopInvoked(BuildContext context, bool didPop) async {
    if (!didPop && mounted) {
      final noteModel = context.read<NoteModel>();
      final navigator = Navigator.of(context);
      final currentContent = noteModel.content;

      if (!_isEditing ||
          (_originalNote != null && currentContent == _originalNote!.content) ||
          (await DialogService.showUnsavedChangesDialog(context) ?? false)) {
        // Return null when user cancels without saving
        navigator.pop(null);
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var noteModel = NoteModel();
    noteModel.isPrivate = note?.isPrivate ?? true;
    noteModel.isMarkdown = note?.isMarkdown ?? false;
    noteModel.content = note?.content ?? '';

    return ChangeNotifierProvider(
        create: (_) => noteModel,
        builder: (context, child) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) => _onPopInvoked(context, didPop),
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Consumer<NoteModel>(builder: (context, noteModel, child) {
                  // Define IconButton callback that can be reused
                  _saveNoteHandler = () => _saveNote(noteModel);

                  return AppBar(
                    title: Text(
                      '${note?.id} - ${noteModel.isPrivate ? 'Private' : 'Public'}${noteModel.isMarkdown ? ' with M↓' : ''}',
                      style: TextStyle(
                        color: noteModel.isPrivate ? Colors.red : Colors.green, // Change colors accordingly
                      ),
                    ),
                    actions: [
                      if (note?.userId == UserSession().id) ...[
                        if (_isEditing)
                          IconButton(
                            icon: _isSaving
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.check),
                            onPressed: _saveNoteHandler,
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _enterEditingMode,
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await DialogService.showConfirmDialog(
                                context,
                                title: 'Delete note',
                                text: 'Each note is a story, are you sure you want to delete it?',
                                yesCallback: _deleteNote,
                              );
                            } else if (value == 'undelete') {
                              await DialogService.showConfirmDialog(
                                context,
                                title: 'Undelete note',
                                text: 'Are you sure you want to undelete this note?',
                                yesCallback: _undeleteNote,
                              );
                            } else if (value == 'trash_bin') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TrashBinPage()),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<String>(
                                value: note?.deletedAt != null ? 'undelete' : 'delete',
                                child: Text(note?.deletedAt != null ? 'Undelete' : 'Delete'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'trash_bin',
                                child: Text('Trash Bin'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ],
                  );
                }),
              ),
              body: GestureDetector(
                onDoubleTap: _enterEditingMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Publish time
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                      child: Text(
                        'Published on ${note?.createdDate} at ${note?.createdTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: Consumer<NoteModel>(
                          builder: (context, noteModel, child) {
                            if (note == null) {
                              return const Text("Note doesn't exist, or, you don't have permission to read it.");
                            }
                            return Column(
                              children: [
                                if (note?.deletedAt != null)
                                  Container(
                                    width: double.infinity,
                                    color: Colors.red.withValues(alpha: 0.2),
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'You are viewing a deleted note',
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                Expanded(
                                  child: _isEditing
                                    ? NoteEdit(
                                        note: note!,
                                        onSubmit: _saveNoteHandler,
                                      )
                                    : NoteView(note: note!),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
