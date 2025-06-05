import 'package:flutter/material.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/screens/components/tag_widget.dart';

import '../../../entities/note.dart';
import '../markdown_body_here.dart';
import 'note-list.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final ListItemCallbacks<Note> callbacks;
  final ListItemConfig config;
  final void Function(Note note, String tag)? onTagTap;

  const NoteListItem({
    super.key,
    required this.note,
    required this.callbacks,
    required this.config,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = _buildContent(context);

    if (config.enableDismiss && callbacks.onDelete != null) {
      return Dismissible(
        key: Key(note.id.toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: callbacks.confirmDismiss,
        onDismissed: (_) => callbacks.onDelete!(note),
        background: _buildDismissBackground(),
        child: child,
      );
    }

    return child;
  }

 Widget _buildContent(BuildContext context) {
   return Stack(
     children: [
       GestureDetector(
         onTap: () => callbacks.onTap?.call(note),
         onDoubleTap: () => callbacks.onDoubleTap?.call(note),
         child: Container(
           color: config.backgroundColor,
           padding: config.padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildMetadata(),
               _buildNoteContent(),
               if ((note.tags?.isNotEmpty == true || note.isLong) && !config.showRestoreButton) _buildFooter(),
             ],
           ),
         ),
       ),
       if (config.showRestoreButton && note.isDeleted)
         Positioned.fill(
           child: GestureDetector(
             onTap: () => callbacks.onRestore?.call(note),
             child: Center(
               child: Container(
                 decoration: BoxDecoration(
                   color: Colors.blue,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                 child: const Text(
                   'Restore',
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.white,
                     fontWeight: FontWeight.w500,
                   ),
                   overflow: TextOverflow.visible,
                 ),
               ),
             ),
           ),
         ),
     ],
   );
 }

  Widget _buildMetadata() {
    final showDate = config.showDate;
    final showAuthor = config.showAuthor;
    final author = (note.user == null || !showAuthor || note.userId == UserSession().id) ? '' : '${note.user!.username} ';
    final date = showDate ? '${note.createdDate} ' : '';

    return Row(
      children: [
        Text(
          '- $date${note.createdTime} $author - ',
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            color: Colors.blue,
            fontSize: 13,
          ),
        ),
        if (note.isPrivate) ...[
          Icon(Icons.lock, color: Colors.grey.shade300, size: 14),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
        Text(
          ' ${note.id} ',
          style: TextStyle(
            fontWeight: FontWeight.w100,
            color: Colors.blue.shade300,
            fontSize: 13,
          ),
        ),
        const Icon(Icons.open_in_new, color: Colors.blue, size: 14),
      ],
    );
  }

  Widget _buildNoteContent() {
    final content = note.content + (note.isLong ? '...' : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: note.isMarkdown
          ? MarkdownBodyHere(data: content, isPrivate: note.isPrivate)
          : SelectableText(
        content,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: note.isPrivate ? Colors.black54 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (note.tags?.isNotEmpty ?? false)
          Wrap(
            spacing: 8,
            children: note.tags!.map((tag) => TagWidget(
              tag: tag,
              onTap: onTagTap != null ? () => onTagTap!(note, tag) : null,
            )).toList(),
          ),
        if (note.isLong)
          const Text('View more', style: TextStyle(color: Colors.blue)),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}