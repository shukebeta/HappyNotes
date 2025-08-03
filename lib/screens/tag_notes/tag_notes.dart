import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/screens/tag_notes/tag_notes_controller.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import '../../utils/navigation_helper.dart';
import '../components/floating_pagination.dart';
import '../components/note_list/note_list.dart';
import '../components/note_list/note_list_callbacks.dart';
import '../components/pagination_controls.dart';
import '../../dependency_injection.dart';
import '../account/user_session.dart';
import '../new_note/new_note.dart';
import '../components/tappable_app_bar_title.dart';
import '../components/list_grouper.dart';
import '../../entities/note.dart';

class TagNotes extends StatefulWidget {
  final String tag;
  final bool myNotesOnly;

  const TagNotes({super.key, required this.tag, required this.myNotesOnly});

  @override
  TagNotesState createState() => TagNotesState();
}

class TagNotesState extends State<TagNotes> {
  late TagNotesController _tagNotesController;
  late TagCloudController _tagCloudController;
  int currentPageNumber = 1;
  bool showPageSelector = false;
  bool get isFirstPage => currentPageNumber == 1;
  bool get isLastPage => currentPageNumber == _tagNotesController.totalPages;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tagNotesController = locator<TagNotesController>();
    _tagCloudController = locator<TagCloudController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      navigateToPage(currentPageNumber);
    }
  }

  Future<bool> navigateToPage(int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= _tagNotesController.totalPages) {
      await _tagNotesController.loadNotes(context, widget.tag, pageNumber);
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
          onTap: () =>
              NavigationHelper.showTagInputDialog(context, replacePage: true),
          onLongPress: () async {
            final navigator = Navigator.of(context);
            var tagData = await _tagCloudController.loadTagCloud(context);
            // Show tag diagram on long press
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData,
                myNotesOnly: widget.myNotesOnly);
          },
        ),
        actions: [
          _buildNewNoteButton(context),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_tagNotesController.totalPages > 1 && !UserSession().isDesktop)
            FloatingPagination(
              currentPage: currentPageNumber,
              totalPages: _tagNotesController.totalPages,
              navigateToPage: navigateToPage,
            ),
        ],
      ),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
              initialTag: widget.tag,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_tagNotesController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tagNotesController.notes.isEmpty) {
      return const Center(
          child: Text('No notes available. Create a new note to get started.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NoteList(
            groupedNotes: ListGrouper.groupByDate(_tagNotesController.notes, (note) => note.createdDate),
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
                    builder: (context) => NoteDetail(
                        note: note,
                        enterEditing: note.userId == UserSession().id),
                  ),
                );
                navigateToPage(currentPageNumber);
              },
              onDelete: (note) async {
                await _tagNotesController.deleteNote(context, note.id);
              },
            ),
            noteCallbacks: NoteListCallbacks(
              onTagTap: (note, tag) =>
                  NavigationHelper.onTagTap(context, note, tag),
              onRefresh: () async => await navigateToPage(currentPageNumber),
            ),
            config: const ListItemConfig(
              showDate: false,
              showRestoreButton: false,
              enableDismiss: true,
            ),
          ),
        ),
        if (_tagNotesController.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _tagNotesController.totalPages,
            navigateToPage: navigateToPage,
          ),
      ],
    );
  }
}
