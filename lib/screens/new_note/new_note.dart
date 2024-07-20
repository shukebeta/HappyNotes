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
  final SaveNoteCallback? onNoteSaved;

  const NewNote({Key? key, required this.isPrivate, this.onNoteSaved}) : super(key: key);

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final _newNoteController = locator<NewNoteController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var noteModel = NoteModel();
    noteModel.isPrivate = widget.isPrivate;
    noteModel.isMarkdown = AppConfig.markdownIsEnabled;
    noteModel.content = '';
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
              body: Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 4.0),
                child: Consumer<NoteModel>(
                  builder: (context, noteModel, child) {
                    return const NoteEdit();
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  final noteModel = context.read<NoteModel>();
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
