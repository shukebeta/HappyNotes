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

// ignore: must_be_immutable
class NoteDetail extends StatefulWidget {
  final Note? note;
  final int? noteId;
  bool? enterEditing;

  NoteDetail({super.key, this.note, this.noteId, this.enterEditing});

  @override
  NoteDetailState createState() => NoteDetailState();
}

class NoteDetailState extends State<NoteDetail> with RouteAware {
  Note? note;
  List<Note>? linkedNotes = [];
  late NoteDetailController _controller;
  bool _initialized = false;


  @override
  void initState() {
    _controller = NoteDetailController(notesService: locator<NotesService>());
    _controller.isEditing = widget.enterEditing ?? false;
    note = widget.note;
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
    }
    setState(() {});
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
                      'Note ${note?.id} - ${noteModel.isPrivate ? 'Private' : 'Public'}${noteModel.isMarkdown ? ' with M↓'  : ''}',
                      style: TextStyle(
                        color: noteModel.isPrivate ? Colors.red : Colors.green, // Change colors accordingly
                      ),
                    ),
                    actions: [
                      if (note?.userId == UserSession().id) ...[
                        if (_controller.isEditing)
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              var navigator = Navigator.of(context);
                              _controller.saveNote(
                                context,
                                note?.id ?? widget.noteId!,
                                  () => navigator.pop(true),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Consumer<NoteModel>(
                    builder: (context, noteModel, child) {
                      if (note == null) return const Text("Note doesn't exist, or, you don't have permission to read it.");
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
                            child: _controller.isEditing
                                ? NoteEdit(note: note!)
                                : NoteView(note: note!),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        });
  }
}
