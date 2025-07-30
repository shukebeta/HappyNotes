import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/components/note_list/note-list.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/util.dart';
import '../components/floating_pagination.dart';
import '../components/list_grouper.dart';
import '../components/note_list/note-list-callbacks.dart';
import '../components/pagination_controls.dart';
import '../../dependency_injection.dart';
import '../account/user_session.dart';
import '../new_note/new_note.dart';
import 'discovery_controller.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

class Discovery extends StatefulWidget {
  const Discovery({super.key});

  @override
  DiscoveryState createState() => DiscoveryState();
}

class DiscoveryState extends State<Discovery> {
  late DiscoveryController _discoveryController;
  late TagCloudController _tagCloudController;
  int currentPageNumber = 1;
  bool showPageSelector = false;

  bool get isFirstPage => currentPageNumber == 1;

  bool get isLastPage => currentPageNumber == _discoveryController.totalPages;

  @override
  void initState() {
    super.initState();
    _discoveryController = locator<DiscoveryController>();
    _tagCloudController = locator<TagCloudController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navigateToPage(currentPageNumber);
  }

  Future<bool> navigateToPage(int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= _discoveryController.totalPages) {
      await _discoveryController.loadNotes(context, pageNumber);
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
          title: 'My Notes',
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            var tagData = await _tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(context, tagData);
          },
        ),
        actions: [
          _buildNewNoteButton(context),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_discoveryController.totalPages > 1 && !UserSession().isDesktop)
            FloatingPagination(
              currentPage: currentPageNumber,
              totalPages: _discoveryController.totalPages,
              navigateToPage: navigateToPage,
            ),
        ],
      ),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: Util.writeNoteIcon(),
      tooltip: AppConfig.privateNoteOnlyIsEnabled ? 'New Private Note' : 'New Public Note',
      onPressed: () async {
        // Await the result
        final bool? savedSuccessfully = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
            ),
          ),
        );
        if (savedSuccessfully ?? false) {
          // Only refresh if on the first page, otherwise let the snackbar handle it (existing logic)
          if (isFirstPage) {
            await refreshPage();
          } else {
            Util.showInfo(ScaffoldMessenger.of(context), 'Note saved successfully.'); // Replaced showSnackBar
          }
        }
      },
    );
  }

  Widget _buildBody() {
    if (_discoveryController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_discoveryController.notes.isEmpty) {
      return const Center(child: Text('No notes available. Create a new note to get started.'));
    }

    final groupedNotes = ListGrouper.groupByDate(_discoveryController.notes, (note) => note.createdDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NoteList(
            groupedNotes: groupedNotes,
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
                await _discoveryController.deleteNote(context, note.id);
              },
            ),
            noteCallbacks: NoteListCallbacks(
              onTagTap: (note, tag) => (note, tag) => NavigationHelper.onTagTap(context, note, tag),
              onDateHeaderTap: (date) => {},
            ),
            config: const ListItemConfig(
              showDate: false,
              showAuthor: true, // Show author for discovery page
              showRestoreButton: false,
              enableDismiss: true,
            ),
          ),
        ),
        if (_discoveryController.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _discoveryController.totalPages,
            navigateToPage: navigateToPage,
          ),
      ],
    );
  }
}
