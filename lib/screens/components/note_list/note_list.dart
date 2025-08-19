import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../entities/note.dart';
import '../../../providers/note_list_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../services/seq_logger.dart';
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
    // 尝试获取各种可能的 NoteListProvider 实现
    NoteListProvider? provider;
    try {
      provider = Provider.of<NotesProvider?>(context, listen: false);
    } catch (e) {
      // 如果找不到 NotesProvider，尝试其他类型
      try {
        provider = Provider.of<NoteListProvider?>(context, listen: false);
      } catch (e) {
        provider = null;
      }
    }

    // Web 环境下，如果是移动平台（iOS/Android）或者支持触摸，都启用拉动功能
    final isMobile = (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS) ||
                     (kIsWeb && MediaQuery.of(context).size.width < 768);

    final pullUpEnabled = isMobile && provider != null;


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
      canAutoLoadNext: provider?.canAutoLoadNext() ?? false,
      isAutoLoading: provider?.isAutoLoading ?? false,
      onLoadMore: provider?.autoLoadNext,
      pullUpToLoadEnabled: isMobile && provider != null,

      // Pull-down functionality
      canAutoLoadPrevious: provider?.canAutoLoadPrevious() ?? false,
      onLoadPrevious: provider?.autoLoadPrevious,
      pullDownToLoadEnabled: isMobile && provider != null,
      currentPage: provider?.currentPage ?? 1,
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