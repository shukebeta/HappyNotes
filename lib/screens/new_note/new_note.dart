import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import '../../dependency_injection.dart';
import '../../models/note_model.dart';
import '../../typedefs.dart';
import '../components/note_edit.dart';

class NewNote extends StatefulWidget {
  final bool isPrivate;
  final String? initialTag;
  final SaveNoteCallback? onNoteSaved;

  const NewNote({
    Key? key,
    required this.isPrivate,
    this.initialTag,
    this.onNoteSaved,
  }) : super(key: key);

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final _newNoteController = locator<NewNoteController>();
  late NoteModel noteModel;

  @override
  void initState() {
    super.initState();
    noteModel = NoteModel();
    noteModel.isPrivate = widget.isPrivate;
    noteModel.isMarkdown = AppConfig.markdownIsEnabled;
    noteModel.content = '';
    if (widget.initialTag != null) {
      noteModel.initialTag = widget.initialTag!;
    }
  }

  @override
  void dispose() {
    noteModel.unfocus(); // Unfocus the text field when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => noteModel,
        builder: (context, child) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) => _newNoteController.onPopHandler(context, didPop),
            child: Scaffold(
              appBar: AppBar(
                title: Consumer<NoteModel>(
                  builder: (context, noteModel, child) {
                    return Text(noteModel.isPrivate ? 'Private Note' : 'Public Note');
                  },
                ),
              ),
              body: const Padding(
                padding: EdgeInsets.fromLTRB(4.0, 0, 4.0, 4.0),
                child: NoteEdit(),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  _newNoteController.saveNote(
                    context,
                    widget.onNoteSaved,
                  );
                },
                child: const Icon(Icons.save),
              ),
            ),
          );
        });
  }
}
