import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/note_edit.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/dialog_services.dart';
import '../account/user_session.dart';
import '../components/note_view.dart';
import '../trash_bin/trash_bin_page.dart';
import '../../providers/notes_provider.dart';
import '../../utils/util.dart';

class NoteDetail extends StatefulWidget {
  final Note? note;
  final int? noteId;
  final bool? enterEditing;
  final VoidCallback? onNoteSaved; // Callback when note is saved
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
    bool includeDeleted = widget.note?.deletedAt != null;
    
    final fetchedNote = await notesProvider.getNote(
      note?.id ?? widget.noteId!,
      includeDeleted: includeDeleted,
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

  void _updateNoteContent(NoteModel noteModel) {
    // Update the note content in the NoteModel
    note = Note(
      id: note!.id,
      userId: note!.userId,
      content: noteModel.content,
      isPrivate: noteModel.isPrivate,
      isLong: note!.isLong,
      isMarkdown: noteModel.isMarkdown,
      createdAt: note!.createdAt,
      deletedAt: note!.deletedAt,
      user: note!.user,
      tags: note!.tags,
    );
  }

  @override
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _saveNote(NoteModel noteModel) async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final success = await notesProvider.updateNote(
      note?.id ?? widget.noteId!,
      noteModel.content,
      isPrivate: noteModel.isPrivate,
      isMarkdown: noteModel.isMarkdown,
    );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      _isEditing = false;
      widget.onNoteSaved?.call();
      if (_editingFromDetailPage) {
        _updateNoteContent(noteModel);
      } else {
        navigator.pop(true);
      }
      if (mounted) {
        Util.showInfo(scaffoldMessenger, 'Note successfully updated.');
      }
    } else if (mounted) {
      Util.showError(scaffoldMessenger, 'Failed to update note');
    }
  }

  Future<void> _deleteNote() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final success = await notesProvider.deleteNote(note?.id ?? widget.noteId!);
    
    if (success) {
      navigator.pop(true);
      if (mounted) {
        Util.showInfo(scaffoldMessenger, 'Note successfully deleted.');
      }
    } else if (mounted) {
      Util.showError(scaffoldMessenger, 'Failed to delete note');
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
        navigator.pop(false);
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
