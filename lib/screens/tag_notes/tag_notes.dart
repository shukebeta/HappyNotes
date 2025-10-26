import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/providers/tag_notes_provider.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import '../../utils/navigation_helper.dart';
import 'package:happy_notes/screens/search/search_results_page.dart';
import '../components/floating_pagination.dart';
import '../components/note_list/note_list.dart';
import '../components/note_list/note_list_callbacks.dart';
import '../components/pagination_controls.dart';
import '../account/user_session.dart';
import '../new_note/new_note.dart';
import '../components/tappable_app_bar_title.dart';
import '../../entities/note.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/components/shared_fab.dart';
import 'package:happy_notes/utils/util.dart';

class TagNotes extends StatefulWidget {
  final String tag;
  final bool myNotesOnly;

  const TagNotes({super.key, required this.tag, required this.myNotesOnly});

  @override
  TagNotesState createState() => TagNotesState();
}

class TagNotesState extends State<TagNotes> {
  int currentPageNumber = 1;
  bool showPageSelector = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tagProvider = context.read<TagNotesProvider>();
        tagProvider.loadTagNotes(widget.tag, currentPageNumber);
      });
    }
  }

  Future<bool> navigateToPage(int pageNumber) async {
    final tagProvider = context.read<TagNotesProvider>();
    if (pageNumber >= 1 && pageNumber <= tagProvider.totalPages) {
      await tagProvider.loadTagNotes(widget.tag, pageNumber);
      setState(() {
        currentPageNumber = pageNumber;
        showPageSelector = false;
      });
      return true;
    }
    return false;
  }

  Future<bool> refreshPage() async {
    return await navigateToPage(currentPageNumber);
  }

  @override
  Widget build(BuildContext context) {
    UserSession().isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: TappableAppBarTitle(
          title: 'Notes with tag: ${widget.tag}',
          onTap: () => NavigationHelper.showTagInputDialog(context, replacePage: true),
          onLongPress: () async {
            final navigator = Navigator.of(context);
            final tagCloudController = TagCloudController();
            final tagData = await tagCloudController.loadTagCloud(context);
            // Show tag diagram on long press
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData, myNotesOnly: widget.myNotesOnly);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Text',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsPage(query: widget.tag),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TagNotesProvider>(
        builder: (context, tagProvider, child) {
          return Stack(
            children: [
              _buildBody(),
              if (tagProvider.totalPages > 1 && !UserSession().isDesktop)
                FloatingPagination(
                  currentPage: currentPageNumber,
                  totalPages: tagProvider.totalPages,
                  navigateToPage: navigateToPage,
                ),
              SharedFab(
                icon: Icons.edit_outlined,
                isPrivate: AppConfig.privateNoteOnlyIsEnabled,
                busy: false,
                mini: false,
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final tagProvider = context.read<TagNotesProvider>();
                  final Note? savedNote = await Navigator.push<Note>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewNote(
                        isPrivate: AppConfig.privateNoteOnlyIsEnabled,
                        initialTag: widget.tag,
                      ),
                    ),
                  );

                  if (savedNote != null && mounted) {
                    // Check if saved note contains the current tag
                    final noteContainsTag = savedNote.tags?.contains(widget.tag) ?? false;

                    if (noteContainsTag && currentPageNumber == 1) {
                      // Optimistically insert the note at the top
                      tagProvider.insertNoteIfOnFirstPage(savedNote);
                    } else {
                      // Show success message
                      Util.showInfo(scaffoldMessenger, 'Note saved successfully.');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildBody() {
    return Consumer<TagNotesProvider>(
      builder: (context, tagProvider, child) {
        if (tagProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tagProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${tagProvider.error}'),
                ElevatedButton(
                  onPressed: () => navigateToPage(currentPageNumber),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (tagProvider.notes.isEmpty) {
          return const Center(
            child: Text('No notes available. Create a new note to get started.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ChangeNotifierProvider<NoteListProvider>.value(
                value: tagProvider,
                child: NoteList(
                  groupedNotes: tagProvider.groupedNotes,
                  showDateHeader: true,
                  callbacks: ListItemCallbacks<Note>(
                    onTap: (note) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(note: note),
                        ),
                      );
                      await navigateToPage(currentPageNumber);
                    },
                    onDoubleTap: (note) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(note: note, enterEditing: note.userId == UserSession().id),
                        ),
                      );
                      navigateToPage(currentPageNumber);
                    },
                    onDelete: (note) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await tagProvider.deleteNote(note.id);
                      if (result.isError && mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Delete failed: ${result.errorMessage}')),
                        );
                      }
                      await navigateToPage(currentPageNumber);
                    },
                  ),
                  noteCallbacks: NoteListCallbacks(
                    onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
                    onRefresh: () async => await navigateToPage(currentPageNumber),
                  ),
                  config: const ListItemConfig(
                    showDate: false,
                    showRestoreButton: false,
                    enableDismiss: true,
                  ),
                ),
              ),
            ),
            if (tagProvider.totalPages > 1 && UserSession().isDesktop)
              PaginationControls(
                currentPage: currentPageNumber,
                totalPages: tagProvider.totalPages,
                navigateToPage: navigateToPage,
              ),
          ],
        );
      },
    );
  }
}
