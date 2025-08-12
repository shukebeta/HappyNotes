import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/components/note_list/note_list.dart';
import 'package:happy_notes/screens/components/note_list/note_list_callbacks.dart';
import 'package:happy_notes/providers/search_provider.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/utils/navigation_helper.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/screens/new_note/new_note.dart';
import 'package:happy_notes/utils/util.dart';
import 'package:happy_notes/screens/components/floating_pagination.dart';
import 'package:happy_notes/screens/components/pagination_controls.dart';
import 'package:happy_notes/screens/components/tappable_app_bar_title.dart';
import 'package:happy_notes/entities/note.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  int currentPageNumber = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateToPage(currentPageNumber);
    });
  }

  Future<bool> navigateToPage(int pageNumber) async {
    final searchProvider = context.read<SearchProvider>();
    if (pageNumber >= 1 && pageNumber <= searchProvider.totalPages) {
      await searchProvider.searchNotes(widget.query, pageNumber);
      currentPageNumber = pageNumber;
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
            final navigator = Navigator.of(context);
            final tagCloudController = TagCloudController();
            final tagData = await tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData,
                myNotesOnly: true);
          },
        ),
        actions: [
          IconButton(
            icon: Util.writeNoteIcon(),
            tooltip: 'New Public Note',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final bool? savedSuccessfully = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewNote(
                    isPrivate: false,
                  ),
                ),
              );
              if (savedSuccessfully ?? false) {
                if (!mounted) return;
                Util.showInfo(scaffoldMessenger, 'Note saved successfully.');
              }
            },
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          return Stack(
            children: [
              _buildBody(searchProvider),
              if (searchProvider.totalPages > 1 && !UserSession().isDesktop)
                FloatingPagination(
                  currentPage: currentPageNumber,
                  totalPages: searchProvider.totalPages,
                  navigateToPage: navigateToPage,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: ${searchProvider.error}',
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (searchProvider.searchResults.isEmpty) {
      return const Center(child: Text('No notes found matching your query.'));
    }

    return Column(
      children: [
        Expanded(
          child: NoteList(
            groupedNotes: searchProvider.groupedNotes,
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
                final result = await searchProvider.deleteNote(note.id);
                if (result.isSuccess && mounted) {
                  Util.showInfo(ScaffoldMessenger.of(context), 'Note deleted successfully.');
                } else if (result.isError && mounted) {
                  Util.showError(ScaffoldMessenger.of(context), result.errorMessage!);
                }
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
        if (searchProvider.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
              currentPage: currentPageNumber,
              totalPages: searchProvider.totalPages,
              navigateToPage: navigateToPage),
      ],
    );
  }
}
