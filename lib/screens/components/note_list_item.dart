import 'package:flutter/material.dart';
import 'package:happy_notes/screens/account/user_session.dart';
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
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '- ${note.createTime}  ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                  ),
                ),
                if (note.isPrivate)
                  const Icon(
                    Icons.lock,
                    color: Colors.blueGrey,
                    size: 14,
                  ),
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                ),
                if (note.user != null && note.user!.email != UserSession().email)
                  Positioned(
                    top: 2,
                    right: 56,
                    child: Image.network(
                      note.user!.gravatar,
                      width: 25,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        return const Text('Failed to load image');
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                note.isMarkdown
                    ? MarkdownBodyHere(
                        data: note.content + (note.isLong ? '...' : ''),
                      )
                    : RichText(
                        text: TextSpan(
                          text: note.content + (note.isLong ? '...' : ''),
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
                      children: [
                        if (note.isLong)
                          const Text(
                            'View more',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ...note.tags!.map((tag) {
                          return TagWidget(
                            tag: tag,
                            onTap: () => onTagTap == null ? () {} : onTagTap!(tag),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
