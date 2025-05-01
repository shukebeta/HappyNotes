import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/note_list.dart';
import 'package:happy_notes/screens/search/search_results_controller.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/utils/navigation_helper.dart';
import 'package:happy_notes/screens/account/user_session.dart'; // For onDoubleTap logic
import 'package:happy_notes/screens/components/floating_pagination.dart'; // Import pagination
import 'package:happy_notes/screens/components/pagination_controls.dart'; // Import pagination
import 'package:happy_notes/screens/components/tappable_app_bar_title.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late SearchResultsController _controller;
  late TagCloudController _tagCloudController;
  int currentPageNumber = 1; // Add state for current page

  @override
  void initState() {
    super.initState();
    _controller = locator<SearchResultsController>();
    _tagCloudController = locator<TagCloudController>();
    // Add listener to rebuild when controller notifies changes
    _controller.addListener(_onControllerUpdate);
    // Fetch initial page
    navigateToPage(currentPageNumber);
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    // Trigger a rebuild when the controller's state changes
    setState(() {});
  }

  // Method to navigate to a specific page
  Future<bool> navigateToPage(int pageNumber) async {
    // Check if pageNumber is valid (using controller's totalPages)
    if (pageNumber >= 1 && pageNumber <= _controller.totalPages) {
      await _controller.fetchSearchResults(widget.query, pageNumber);
      // Update local state only after successful fetch (controller updates its own state)
      // No need to call setState here if listener handles it, but update local page number
      currentPageNumber = pageNumber;
      // Ensure listener triggers rebuild if needed, or call setState if listener doesn't cover page number change display
      setState(() {}); // Update local page number state
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Wrap title in GestureDetector for tap/long-press actions
        title: TappableAppBarTitle(
          title: 'Search: "${widget.query}"',
          onTap: () =>
              NavigationHelper.showTagInputDialog(context, replacePage: true),
          onLongPress: () async {
            var tagData = await _tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            // Assuming myNotesOnly=true is desired for tag cloud from search results
            NavigationHelper.showTagDiagram(context, tagData,
                myNotesOnly: true);
          },
        ),
      ),
      // Use Stack to overlay pagination controls
      body: Stack(
        children: [
          _buildBody(),
          // Add pagination controls similar to HomePage/TagNotes
          if (_controller.totalPages > 1 && !UserSession().isDesktop)
            FloatingPagination(
              currentPage: currentPageNumber, // Use local state
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

    // Display results using NoteList
    // Wrap NoteList in a Column to add desktop pagination controls below it
    return Column(
      children: [
        Expanded(
          child: NoteList(
            notes: _controller.results,
            showDateHeader:
                true, // Or false, depending on desired display for search
            onTap: (note) async {
              // Navigate to detail, refresh if needed (standard pattern)
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NoteDetail(note: note)));
              // Refresh current page after returning from detail.
              navigateToPage(currentPageNumber);
            },
            onDoubleTap: (note) async {
              // Navigate to detail in edit mode if user owns the note
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NoteDetail(
                          note: note,
                          enterEditing: note.userId == UserSession().id)));
              // Refresh current page after returning from detail.
              navigateToPage(currentPageNumber);
            },
            onTagTap: (note, tag) =>
                NavigationHelper.onTagTap(context, note, tag),
            onRefresh: () => navigateToPage(
                currentPageNumber), // Use navigateToPage for refresh
            onDelete: (note) async {
              await _controller.deleteNote(context, note.id);
            },
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
