import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/components/note_list/note_list.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../components/floating_pagination.dart';
import '../components/note_list/note_list_callbacks.dart';
import '../components/pagination_controls.dart';
import '../account/user_session.dart';
import '../components/tappable_app_bar_title.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/note_list_provider.dart';
import '../components/controllers/tag_cloud_controller.dart';

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

  /// Handle the result from NoteDetail editing
  void _handleEditResult(bool? saved) {
    // No action needed - cache updates are handled by NoteUpdateCoordinator
    // This method is kept for potential future use (e.g., analytics, UI feedback)
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
            final tagCloudController = TagCloudController();
            final tagData = await tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData);
          },
        ),
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
              child: ChangeNotifierProvider<NoteListProvider>.value(
                value: discoveryProvider,
                child: NoteList(
                  groupedNotes: discoveryProvider.groupedNotes,
                  showDateHeader: true,
                  callbacks: ListItemCallbacks<Note>(
                    onTap: (note) async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(note: note),
                        ),
                      );
                      _handleEditResult(saved);
                    },
                    onDoubleTap: (note) async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(note: note, enterEditing: note.userId == UserSession().id),
                        ),
                      );
                      _handleEditResult(saved);
                    },
                    onDelete: (note) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await discoveryProvider.deleteNote(note.id);
                      if (result.isError && mounted) {
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
                    showAuthor: true,
                    showRestoreButton: false,
                    enableDismiss: true,
                  ),
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
