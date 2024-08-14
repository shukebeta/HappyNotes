// note_edit.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/utils/happy_notes_prompts.dart';
import '../../app_config.dart';
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

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    final noteModel = context.read<NoteModel>();
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);

    // Delay the update to avoid triggering a rebuild during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteModel.initialTag.isNotEmpty && widget.note == null) {
        noteModel.content = '#${noteModel.initialTag}\n';
        noteModel.initialTag = ''; // Reset after use
      } else if (widget.note != null) {
        noteModel.content = widget.note!.content;
      }

      // Set the initial text in the controller
      controller.text = noteModel.content;

      // Add listener to update controller.text when noteModel.content changes
      noteModel.addListener(() {
        if (noteModel.content != controller.text) {
          controller.text = noteModel.content;
        }
      });

      // Request focus and set prompt
      if (!AppConfig.isIOSWeb) {
        noteModel.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
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
                GestureDetector(
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
                ),
                const SizedBox(width: 24.0),
                GestureDetector(
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
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditor(NoteModel noteModel) {
    return TextField(
      controller: controller,
      focusNode: noteModel.focusNode,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: prompt,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: noteModel.isPrivate ? Colors.blue : Colors.green,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: noteModel.isPrivate ? Colors.blueAccent : Colors.greenAccent,
            width: 2.0,
          ),
        ),
      ),
      onChanged: (text) {
        noteModel.content = text;
      },
    );
  }
}
