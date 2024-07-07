// note_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../models/note_model.dart';

class NoteView extends StatelessWidget {
  final TextEditingController controller;
  final bool isMarkdown;

  const NoteView({
    Key? key,
    required this.controller,
    required this.isMarkdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: Consumer<NoteModel>(
                builder: (context, noteModel, child) {
                  return isMarkdown
                      ? MarkdownBody(
                    data: controller.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16.0),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.grey.shade100,
                        color: Colors.purple.shade900,
                        fontFamily: 'monospace',
                      ),
                      h1: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                      h2: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                    onTapLink: (text, url, title) {
                      if (url != null) {
                        launchUrlString(url); // Assuming you have the url_launcher package added
                      }
                    },
                    imageBuilder: (uri, title, alt) {
                      return Image.network(uri.toString());
                    },
                    selectable: true, // Allow users to select text
                  )
                      : Text(
                    controller.text,
                    style: const TextStyle(fontSize: 16.0),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return Row(
                  children: [
                    const Text('Private'),
                    Switch(
                      value: noteModel.isPrivate,
                      onChanged: null, // Disable switch in view mode
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 24.0),
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return Row(
                  children: [
                    const Text('Markdown'),
                    Switch(
                      value: noteModel.isMarkdown,
                      onChanged: null, // Disable switch in view mode
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
