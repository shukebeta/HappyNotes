import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/screens/components/note_list/note_list.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/util.dart';
import '../components/floating_pagination.dart';
import '../memories/memories_on_day.dart';
import '../components/note_list/note_list_callbacks.dart';
import '../components/pagination_controls.dart';
import '../../dependency_injection.dart';
import '../account/user_session.dart';
import '../new_note/new_note.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late TagCloudController _tagCloudController;

  @override
  void initState() {
    super.initState();
    _tagCloudController = locator<TagCloudController>();
    
    // Initialize provider data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        if (provider.notes.isEmpty && !provider.isLoadingList) {
          provider.loadPage(1);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> navigateToPage(int pageNumber) async {
    if (!mounted) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.loadPage(pageNumber);
  }

  Future<void> refreshPage() async {
    if (!mounted) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshCurrentPage();
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
            final navigator = Navigator.of(context);
            var tagData = await _tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData);
          },
        ),
        actions: [
          _buildNewNoteButton(context),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (ctx, notesProvider, child) {
          return Stack(
            children: [
              _buildBody(notesProvider),
              if (notesProvider.totalPages > 1 && !UserSession().isDesktop)
                FloatingPagination(
                  currentPage: notesProvider.currentPage,
                  totalPages: notesProvider.totalPages,
                  navigateToPage: (pageNumber) => navigateToPage(pageNumber),
                ),
            ],
          );
        },
      ),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: Util.writeNoteIcon(),
      tooltip: AppConfig.privateNoteOnlyIsEnabled ? 'New Private Note' : 'New Public Note',
      onPressed: () async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final provider = Provider.of<NotesProvider>(context, listen: false);
        final Note? savedNote = await Navigator.push<Note>(
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
            ),
          ),
        );
        if (!mounted) return;
        if (savedNote != null) {
          // Smart update: Only refresh if on page 1, otherwise show message
          if (provider.currentPage == 1) {
            // Note was already added optimistically to page 1, no need to refresh
            // The provider handled the optimistic update
          } else {
            Util.showInfo(scaffoldMessenger, 'Note saved successfully.');
          }
        }
      },
    );
  }

  Widget _buildBody(NotesProvider notesProvider) {
    if (notesProvider.isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notesProvider.notes.isEmpty) {
      return const Center(child: Text('No notes available. Create a new note to get started.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NoteList(
            groupedNotes: notesProvider.groupedNotes,
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
                await notesProvider.deleteNote(note.id);
              },
            ),
            noteCallbacks: NoteListCallbacks(
              onRefresh: refreshPage,
              onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
              onDateHeaderTap: (date) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemoriesOnDay(date: date),
                      ),
                    ),
            ),
            config: const ListItemConfig(
              showDate: false, // Don't show individual dates when showDateHeader is true
              showAuthor: false,
              enableDismiss: true,
            ),
          ),
        ),
        if (notesProvider.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
            currentPage: notesProvider.currentPage,
            totalPages: notesProvider.totalPages,
            navigateToPage: (pageNumber) => navigateToPage(pageNumber),
          ),
      ],
    );
  }
}
