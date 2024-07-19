import 'package:flutter/material.dart';
import 'package:happy_notes/typedefs.dart';
import '../../entities/note.dart';
import 'markdown_body_here.dart';
import 'tag_widget.dart'; // Import your TagWidget

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidTagTap? onTagTap;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    this.onDoubleTap,
    this.onTagTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child:  Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                note.isMarkdown
                    ? MarkdownBodyHere(
                        data: note.content + (note.isLong ? '...more' : ''),
                      )
                    : RichText(
                        text: TextSpan(
                          text: note.content + (note.isLong ? '...more' : ''),
                          style: const TextStyle(
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black,
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: note.tags!.map((tag) {
                        return TagWidget(
                          tag: tag,
                          onTap: () => onTagTap == null ? () {} : onTagTap!(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (note.isPrivate)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.lock,
                color: Colors.blueGrey,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
