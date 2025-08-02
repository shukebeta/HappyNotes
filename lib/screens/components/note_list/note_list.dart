import 'package:flutter/material.dart';

import '../../../entities/note.dart';
import '../date_header.dart';
import '../grouped_list_view.dart';
import 'note_list_item.dart';
import 'note_list_callbacks.dart';

class NoteList extends StatelessWidget {
  final Map<String, List<Note>> groupedNotes;
  final ListItemCallbacks<Note> callbacks;
  final NoteListCallbacks noteCallbacks;
  final ListItemConfig config;
  final bool showDateHeader;
  final ScrollController? scrollController;

  const NoteList({
    super.key,
    required this.groupedNotes,
    required this.callbacks,
    required this.noteCallbacks,
    this.config = const ListItemConfig(),
    this.showDateHeader = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GroupedListView<Note>(
      groupedItems: groupedNotes,
      scrollController: scrollController,
      onRefresh: noteCallbacks.onRefresh,
      itemBuilder: (note) => NoteListItem(
        note: note,
        callbacks: callbacks,
        config: config,
        onTagTap: noteCallbacks.onTagTap,
      ),
      headerBuilder: showDateHeader
          ? (dateKey, date) => DateHeader(
        date: date,
        onTap: noteCallbacks.onDateHeaderTap != null
            ? () => noteCallbacks.onDateHeaderTap!(date)
            : null,
      )
          : null,
    );
  }
}


class ListItemConfig {
  final bool showDate;
  final bool showAuthor;
  final bool showRestoreButton;
  final bool enableDismiss;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const ListItemConfig({
    this.showDate = false,
    this.showAuthor = false,
    this.showRestoreButton = false,
    this.enableDismiss = false,
    this.backgroundColor,
    this.padding,
  });
}

// 3. Simplified callbacks
class ListItemCallbacks<T> {
  final void Function(T item)? onTap;
  final void Function(T item)? onDoubleTap;
  final void Function(T item)? onDelete;
  final void Function(T item)? onRestore;
  final Future<bool> Function(DismissDirection)? confirmDismiss;

  const ListItemCallbacks({
    this.onTap,
    this.onDoubleTap,
    this.onDelete,
    this.onRestore,
    this.confirmDismiss,
  });
}