// note_edit.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/utils/happy_notes_prompts.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';

class NoteEdit extends StatefulWidget {
  final Note? note;

  const NoteEdit({
    Key? key,
    this.note,
  }) : super(key: key);

  @override
  NoteEditState createState() => NoteEditState();
}

class NoteEditState extends State<NoteEdit> {
  late String prompt;
  late TextEditingController controller;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focusNode = FocusNode();
    final noteModel = context.read<NoteModel>();
    if (noteModel.initialTag != '' && widget.note == null) {
      noteModel.setContent('#${noteModel.initialTag}\n');
      noteModel.resetInitialTag(); // Reset after use
    } else if (widget.note != null) {
      noteModel.setContent(widget.note!.content);
    }
    controller.text = noteModel.content;
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
       focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (context, noteModel, child) {
        return Column(
          children: [
            Expanded(
              child: _buildEditor(noteModel),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Consumer<NoteModel>(
                  builder: (context, noteModel, child) {
                    return GestureDetector(
                      onTap: () {
                        noteModel.isPrivate = !noteModel.isPrivate;
                      },
                      child: Row(
                        children: [
                          const Text('Private'),
                          Switch(
                            value: noteModel.isPrivate,
                            onChanged: (value) {
                              noteModel.isPrivate = value;
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 24.0),
                Consumer<NoteModel>(
                  builder: (context, noteModel, child) {
                    return GestureDetector(
                      onTap: () {
                        noteModel.isMarkdown = !noteModel.isMarkdown;
                      },
                      child: Row(
                        children: [
                          const Text('Markdown'),
                          Switch(
                            value: noteModel.isMarkdown,
                            onChanged: (value) {
                              noteModel.isMarkdown = value;
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  TextField _buildEditor(NoteModel noteModel) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: prompt,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: context.read<NoteModel>().isPrivate ? Colors.blue : Colors.green,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: context.read<NoteModel>().isPrivate ? Colors.blueAccent : Colors.greenAccent,
            width: 2.0,
          ),
        ),
      ),
      onChanged: (text) {
        noteModel.setContent(text);
      },
    );
  }
}
