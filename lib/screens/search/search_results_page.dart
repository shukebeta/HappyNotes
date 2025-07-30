import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/note_list/note-list.dart';
import 'package:happy_notes/screens/components/note_list/note-list-callbacks.dart';
import 'package:happy_notes/screens/search/search_results_controller.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/utils/navigation_helper.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/screens/new_note/new_note.dart';
import 'package:happy_notes/utils/util.dart';
import 'package:happy_notes/screens/components/floating_pagination.dart';
import 'package:happy_notes/screens/components/pagination_controls.dart';
import 'package:happy_notes/screens/components/tappable_app_bar_title.dart';
import 'package:happy_notes/screens/components/list_grouper.dart';
import 'package:happy_notes/entities/note.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late SearchResultsController _controller;
  late TagCloudController _tagCloudController;
  int currentPageNumber = 1;

  @override
  void initState() {
    super.initState();
    _controller = locator<SearchResultsController>();
    _tagCloudController = locator<TagCloudController>();
    _controller.addListener(_onControllerUpdate);
    navigateToPage(currentPageNumber);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  Future<bool> navigateToPage(int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= _controller.totalPages) {
      await _controller.fetchSearchResults(widget.query, pageNumber);
      currentPageNumber = pageNumber;
      setState(() {});
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TappableAppBarTitle(
          title: 'Search: "${widget.query}"',
          onTap: () =>
              NavigationHelper.showTagInputDialog(context, replacePage: true),
          onLongPress: () async {
            var tagData = await _tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(context, tagData,
                myNotesOnly: true);
          },
        ),
        actions: [
          IconButton(
            icon: Util.writeNoteIcon(),
            tooltip: 'New Public Note',
            onPressed: () async {
              final bool? savedSuccessfully = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewNote(
                    isPrivate: false,
                  ),
                ),
              );
              if (savedSuccessfully ?? false) {
                Util.showInfo(ScaffoldMessenger.of(context), 'Note saved successfully.');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_controller.totalPages > 1 && !UserSession().isDesktop)
            FloatingPagination(
              currentPage: currentPageNumber,
              totalPages: _controller.totalPages,
              navigateToPage: navigateToPage,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: ${_controller.error}',
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_controller.results.isEmpty) {
      return const Center(child: Text('No notes found matching your query.'));
    }

    return Column(
      children: [
        Expanded(
          child: NoteList(
            groupedNotes: ListGrouper.groupByDate(_controller.results, (note) => note.createdDate),
            showDateHeader: true,
            callbacks: ListItemCallbacks<Note>(
              onTap: (note) async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NoteDetail(note: note)));
                if (result == true) {
                  navigateToPage(currentPageNumber);
                }
              },
              onDoubleTap: (note) async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NoteDetail(
                            note: note,
                            enterEditing: note.userId == UserSession().id)));
                if (result == true) {
                  navigateToPage(currentPageNumber);
                }
              },
              onDelete: (note) async {
                await _controller.deleteNote(context, note.id);
              },
            ),
            noteCallbacks: NoteListCallbacks(
              onTagTap: (note, tag) =>
                  NavigationHelper.onTagTap(context, note, tag),
              onRefresh: () => navigateToPage(currentPageNumber),
            ),
            config: const ListItemConfig(
              showDate: false,
              showRestoreButton: false,
              enableDismiss: true,
            ),
          ),
        ),
        if (_controller.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
              currentPage: currentPageNumber,
              totalPages: _controller.totalPages,
              navigateToPage: navigateToPage),
      ],
    );
  }
}
