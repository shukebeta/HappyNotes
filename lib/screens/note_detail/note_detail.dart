import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/note_edit.dart';
import 'package:provider/provider.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/dialog_services.dart';
import '../account/user_session.dart';
import '../components/note_view.dart';
import '../../services/notes_services.dart';
import '../trash_bin/trash_bin_page.dart';
import 'note_detail_controller.dart';

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
  late NoteDetailController _controller;
  bool _initialized = false;
  bool _editingFromDetailPage = false; // Track if editing from detail page
  bool _isSaving = false;

  @override
  void initState() {
    _controller = NoteDetailController(notesService: locator<NotesService>());
    _controller.isEditing = widget.enterEditing ?? false;
    note = widget.note;
    _editingFromDetailPage = widget.fromDetailPage; // Initialize from widget
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (!_initialized) {
      bool includeDeleted = widget.note?.deletedAt != null;
      note = await _controller.fetchNote(
        context,
        note?.id ?? widget.noteId!,
        includeDeleted: includeDeleted,
      );
      _initialized = true;
      setState(() {});
    }
  }

  void _enterEditingMode() async {
    if (note?.userId != UserSession().id) return;
    if (!_controller.isEditing) {
      _controller.isEditing = true;
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

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
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
            onPopInvoked: (didPop) => _controller.onPopHandler(context, didPop),
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Consumer<NoteModel>(builder: (context, noteModel, child) {
                  return AppBar(
                    title: Text(
                      '${note?.id} - ${noteModel.isPrivate ? 'Private' : 'Public'}${noteModel.isMarkdown ? ' with M↓' : ''}',
                      style: TextStyle(
                        color: noteModel.isPrivate ? Colors.red : Colors.green, // Change colors accordingly
                      ),
                    ),
                    actions: [
                      if (note?.userId == UserSession().id) ...[
                        if (_controller.isEditing)
                          IconButton(
                            icon: _isSaving
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.check),
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _isSaving = true;
                                    });
                                    var navigator = Navigator.of(context);
                                    _controller.saveNote(
                                      context,
                                      note?.id ?? widget.noteId!,
                                      () {
                                        setState(() {
                                          _isSaving = false;
                                        });
                                        // Call the onNoteSaved callback if provided
                                        widget.onNoteSaved?.call();
                                        // If editing from detail page, stay on detail page
                                        if (_editingFromDetailPage) {
                                          // Update the note content in the NoteModel
                                          _updateNoteContent(noteModel);
                                        } else {
                                          navigator.pop(true);
                                        }
                                      },
                                    );
                                  },
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
                                yesCallback: () => _controller.deleteNote(
                                  context,
                                  note?.id ?? widget.noteId!,
                                  (needRefresh) => Navigator.of(context).pop(needRefresh),
                                ),
                              );
                            } else if (value == 'undelete') {
                              await DialogService.showConfirmDialog(
                                context,
                                title: 'Undelete note',
                                text: 'Are you sure you want to undelete this note?',
                                yesCallback: () async {
                                  _controller.undeleteNote(
                                    context,
                                    note?.id ?? widget.noteId!,
                                    (needRefresh) => Navigator.of(context).pop(needRefresh),
                                  );
                                },
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
                                    color: Colors.red.withOpacity(0.2),
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'You are viewing a deleted note',
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                Expanded(
                                  child: _controller.isEditing ? NoteEdit(note: note!) : NoteView(note: note!),
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
