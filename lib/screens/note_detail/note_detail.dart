import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/dialog_services.dart';
import '../account/user_session.dart';
import '../components/note_editor.dart';
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

  @override
  void initState() {
    _controller = NoteDetailController(notesService: locator<NotesService>());
    _controller.isEditing = widget.enterEditing ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.isEditing) _controller.noteFocusNode.requestFocus();
    });
    super.initState();
    final noteModel = context.read<NoteModel>();
    noteModel.isPrivate = widget.note.isPrivate;
    noteModel.isMarkdown = widget.note.isMarkdown;
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await _controller.fetchNote(widget.note.id);
    setState(() {});
  }

  void _enterEditingMode() async {
    if (widget.note.userId != UserSession().id) return;
    if (!_controller.isEditing) {
      _controller.isEditing = true;
      _controller.noteFocusNode.requestFocus();
    }
    await _controller.fetchNote(widget.note.id);
    setState(() {});
  }

  @override
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => _controller.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Note Details'),
          actions: [
            if (widget.note.userId == UserSession().id)
              if (_controller.isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    final noteModel = context.read<NoteModel>();
                    _controller.saveNote(
                      context,
                      widget.note.id,
                      noteModel.isPrivate,
                      noteModel.isMarkdown,
                      Navigator.of(context).pop,
                    );
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _enterEditingMode,
                ),
            if (widget.note.userId == UserSession().id)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await DialogService.showConfirmDialog(
                    context,
                    title: 'Delete note',
                    text: 'Each note is a story, are you sure you want to delete it?',
                    yesCallback: () => _controller.deleteNote(context, widget.note.id),
                  );
                },
              ),
          ],
        ),
        body: GestureDetector(
          onDoubleTap: _enterEditingMode,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: NoteEditor(
              controller: _controller.noteController,
              focusNode: _controller.noteFocusNode,
              isEditing: _controller.isEditing,
            ),
          ),
        ),
      ),
    );
  }
}
