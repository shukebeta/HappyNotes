import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/components/note_list/note_list.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/util.dart';
import '../components/floating_pagination.dart';
import '../components/note_list/note_list_callbacks.dart';
import '../components/pagination_controls.dart';
import '../account/user_session.dart';
import '../new_note/new_note.dart';
import '../components/tappable_app_bar_title.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/tag_notes_provider.dart';

class Discovery extends StatefulWidget {
  const Discovery({super.key});

  @override
  DiscoveryState createState() => DiscoveryState();
}

class DiscoveryState extends State<Discovery> {
  int currentPageNumber = 1;
  bool showPageSelector = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final discoveryProvider = context.read<DiscoveryProvider>();
        discoveryProvider.navigateToPage(currentPageNumber);
      });
    }
  }

  Future<bool> navigateToPage(int pageNumber) async {
    final discoveryProvider = context.read<DiscoveryProvider>();
    if (pageNumber >= 1 && pageNumber <= discoveryProvider.totalPages) {
      await discoveryProvider.navigateToPage(pageNumber);
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
          title: 'Discover Notes',
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            final navigator = Navigator.of(context);
            final tagProvider = context.read<TagNotesProvider>();
            await tagProvider.loadTagCloud();
            if (!mounted) return;
            final tagData = Map<String, int>.from(tagProvider.tagCloud);
            NavigationHelper.showTagDiagram(navigator.context, tagData);
          },
        ),
        actions: [
          _buildNewNoteButton(context),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          Consumer<DiscoveryProvider>(
            builder: (context, discoveryProvider, child) {
              if (discoveryProvider.totalPages > 1 && !UserSession().isDesktop) {
                return FloatingPagination(
                  currentPage: currentPageNumber,
                  totalPages: discoveryProvider.totalPages,
                  navigateToPage: navigateToPage,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: Util.writeNoteIcon(),
      tooltip: AppConfig.privateNoteOnlyIsEnabled
          ? 'New Private Note'
          : 'New Public Note',
      onPressed: () async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final savedSuccessfully = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
            ),
          ),
        );
        if (!mounted) return;
        if (savedSuccessfully ?? false) {
          // Only refresh if on the first page, otherwise let the snackbar handle it (existing logic)
          if (currentPageNumber == 1) {
            await refreshPage();
          } else {
            Util.showInfo(scaffoldMessenger, 'Note saved successfully.'); // Replaced showSnackBar
          }
        }
      },
    );
  }

  Widget _buildBody() {
    return Consumer<DiscoveryProvider>(
      builder: (context, discoveryProvider, child) {
        if (discoveryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (discoveryProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${discoveryProvider.error}'),
                ElevatedButton(
                  onPressed: () => navigateToPage(currentPageNumber),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (discoveryProvider.notes.isEmpty) {
          return const Center(child: Text('No notes available. Create a new note to get started.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: NoteList(
                groupedNotes: discoveryProvider.groupedNotes,
                showDateHeader: true,
                callbacks: ListItemCallbacks<Note>(
                  onTap: (note) async {
                    var needRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteDetail(note: note),
                          ),
                        ) ??
                        false;
                    if (needRefresh) {
                      refreshPage();
                    }
                  },
                  onDoubleTap: (note) async {
                    var needRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteDetail(note: note, enterEditing: note.userId == UserSession().id),
                          ),
                        ) ??
                        false;
                    if (needRefresh) {
                      refreshPage();
                    }
                  },
                  onDelete: (note) async {
                    final result = await discoveryProvider.deleteNote(note.id);
                    if (result.isError && mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(content: Text('Delete failed: ${result.errorMessage}')),
                      );
                    }
                  },
                ),
                noteCallbacks: NoteListCallbacks(
                  onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
                  onRefresh: () async => await refreshPage(),
                ),
                config: const ListItemConfig(
                  showDate: false,
                  showAuthor: true, // Show author for discovery page
                  showRestoreButton: false,
                  enableDismiss: true,
                ),
              ),
            ),
            if (discoveryProvider.totalPages > 1 && UserSession().isDesktop)
              PaginationControls(
                currentPage: currentPageNumber,
                totalPages: discoveryProvider.totalPages,
                navigateToPage: navigateToPage,
              ),
          ],
        );
      },
    );
  }
}