import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/util.dart';
import '../components/floating_pagination.dart';
import '../components/note_list.dart';
import '../components/pagination_controls.dart';
import '../../dependency_injection.dart';
import '../account/user_session.dart';
import '../new_note/new_note.dart';
import 'home_page_controller.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomePageController _homePageController;
  late TagCloudController _tagCloudController;
  int currentPageNumber = 1;
  bool showPageSelector = false;

  bool get isFirstPage => currentPageNumber == 1;

  bool get isLastPage => currentPageNumber == _homePageController.totalPages;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _homePageController = locator<HomePageController>();
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
    if (pageNumber >= 1 && pageNumber <= _homePageController.totalPages) {
      await _homePageController.loadNotes(context, pageNumber);
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
          if (_homePageController.totalPages > 1 && !UserSession().isDesktop)
            FloatingPagination(
              currentPage: currentPageNumber,
              totalPages: _homePageController.totalPages,
              navigateToPage: navigateToPage,
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
        // final scaffoldContext = ScaffoldMessenger.of(context); // Not needed directly here anymore
        // final navigator = Navigator.of(context); // Not needed directly here anymore
        final bool? savedSuccessfully = await Navigator.push<bool>(
          // Await the result
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
              // onNoteSaved removed
            ),
          ),
        );
        // If savedSuccessfully is true (or not null and true), refresh the page
        if (savedSuccessfully ?? false) {
          // Use ?? false for null safety
          // Only refresh if on the first page, otherwise let the snackbar handle it (existing logic)
          if (isFirstPage) {
            await refreshPage();
          } else {
            // Show snackbar (or handle differently if needed)
            // This part might need adjustment based on desired UX when not on first page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note saved successfully.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildBody() {
    if (_homePageController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homePageController.notes.isEmpty) {
      return const Center(
          child: Text('No notes available. Create a new note to get started.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NoteList(
            showDateHeader: true,
            notes: _homePageController.notes,
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
                      builder: (context) => NoteDetail(
                          note: note,
                          enterEditing: note.userId == UserSession().id),
                    ),
                  ) ??
                  false;
              if (needRefresh) {
                refreshPage();
              }
            },
            onTagTap: (note, tag) =>
                NavigationHelper.onTagTap(context, note, tag),
            onRefresh: () async => await navigateToPage(currentPageNumber),
            onDelete: (note) async {
              await _homePageController.deleteNote(note.id);
            },
          ),
        ),
        if (_homePageController.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _homePageController.totalPages,
            navigateToPage: navigateToPage,
          ),
      ],
    );
  }
}
