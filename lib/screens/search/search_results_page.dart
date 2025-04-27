import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/note_list.dart';
import 'package:happy_notes/screens/search/search_results_controller.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/utils/navigation_helper.dart';
import 'package:happy_notes/screens/account/user_session.dart'; // For onDoubleTap logic

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late SearchResultsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator<SearchResultsController>();
    // Add listener to rebuild when controller notifies changes
    _controller.addListener(_onControllerUpdate);
    _fetchResults();
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

  Future<void> _fetchResults() async {
    // Call controller method to fetch results
    await _controller.fetchSearchResults(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Wrap title in GestureDetector for tap/long-press actions
        title: GestureDetector(
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            var tagData = await _controller.loadTagCloud(context);
            if (!mounted) return;
            // Assuming myNotesOnly=true is desired for tag cloud from search results
            NavigationHelper.showTagDiagram(context, tagData,
                myNotesOnly: true);
          },
          // Wrap Text with Row to add an icon
          child: Row(
            mainAxisSize: MainAxisSize.min, // Prevent Row from expanding
            children: [
              Text('Search: "${widget.query}"'), // Original title text
              const SizedBox(width: 8), // Add some spacing
              const Icon(Icons.touch_app,
                  size: 18, color: Colors.white70), // Add subtle icon
            ],
          ),
        ),
      ),
      body: _buildBody(),
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
    return NoteList(
      notes: _controller.results,
      showDateHeader: true, // Or false, depending on desired display for search
      onTap: (note) async {
        // Navigate to detail, refresh if needed (standard pattern)
        await Navigator.push(context,
            MaterialPageRoute(builder: (context) => NoteDetail(note: note)));
        // Search results don't typically need refresh on pop, but could if needed
      },
      onDoubleTap: (note) async {
        // Navigate to detail in edit mode if user owns the note
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NoteDetail(
                    note: note,
                    enterEditing: note.userId == UserSession().id)));
      },
      onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
      onRefresh: _fetchResults,
      // onDelete might not make sense in search results, omit or handle carefully
    );
  }
}
