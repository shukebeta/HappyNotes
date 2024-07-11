import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../entities/note.dart';
import 'markdown_body_here.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 0),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(
                  child: note.isMarkdown
                      ? MarkdownBodyHere(
                          data: note.content + (note.isLong ? '...more' : ''),
                        )
                      : RichText(
                          text: TextSpan(
                            text: note.content + (note.isLong ? '...more' : ''),
                            style: const TextStyle(
                              fontStyle: FontStyle.normal,
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
