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
import 'note_detail_controller.dart';

// ignore: must_be_immutable
class NoteDetail extends StatefulWidget {
  final Note note;
  bool? enterEditing;

  NoteDetail({super.key, required this.note, this.enterEditing});

  @override
  NoteDetailState createState() => NoteDetailState();
}

class NoteDetailState extends State<NoteDetail> with RouteAware {
  late NoteDetailController _controller;
  late Note note;

  @override
  void initState() {
    _controller = NoteDetailController(notesService: locator<NotesService>());
    _controller.isEditing = widget.enterEditing ?? false;
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    note = await _controller.fetchNote(widget.note.id);
    setState(() {});
  }

  void _enterEditingMode() async {
    if (widget.note.userId != UserSession().id) return;
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
    var noteModel = NoteModel();
    noteModel.isPrivate = widget.note.isPrivate;
    noteModel.isMarkdown = widget.note.isMarkdown;
    noteModel.setContent(note.content);
    return ChangeNotifierProvider(
        create: (_) => noteModel,
        builder: (context, child) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) => _controller.onPopHandler(context, didPop),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Note Details'),
                actions: [
                  if (widget.note.userId == UserSession().id) ...[
                    if (_controller.isEditing)
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          _controller.saveNote(
                            context,
                            widget.note.id,
                            Navigator.of(context).pop,
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
                            yesCallback: () => _controller.deleteNote(context, widget.note.id),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ];
                      },
                    ),
                  ],
                ],
              ),
              body: GestureDetector(
                onDoubleTap: _enterEditingMode,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer<NoteModel>(
                    builder: (context, noteModel, child) {
                      return _controller.isEditing ? NoteEdit(note: note) : NoteView(note: note);
                    },
                  ),
                ),
              ),
            ),
          );
        });
  }
}
