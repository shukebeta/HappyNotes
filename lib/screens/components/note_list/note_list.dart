import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import '../../../entities/note.dart';
import '../../../providers/note_list_provider.dart';
import '../../../utils/app_logger_interface.dart';
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
    final logger = GetIt.instance<AppLoggerInterface>();
    final provider = Provider.of<NoteListProvider?>(context);
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
                     defaultTargetPlatform == TargetPlatform.iOS;
    
    logger.d('[NoteList] Platform detection: defaultTargetPlatform=$defaultTargetPlatform, kIsWeb=$kIsWeb, isMobile=$isMobile');
    logger.d('[NoteList] Provider: ${provider.runtimeType}, isNull=${provider == null}');
    if (provider != null) {
      final canAutoLoad = provider.canAutoLoadNext();
      logger.d('[NoteList] Provider details: canAutoLoadNext=$canAutoLoad, isAutoLoading=${provider.isAutoLoading}, currentPage=${provider.currentPage}, totalPages=${provider.totalPages}');
    }
    final pullUpEnabled = isMobile && provider != null;
    logger.d('[NoteList] Final pullUpToLoadEnabled=$pullUpEnabled');

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