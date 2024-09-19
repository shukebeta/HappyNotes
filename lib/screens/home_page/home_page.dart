import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/screens/tag_notes/tag_notes.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/util.dart';
import '../components/floating_pagination.dart';
import '../components/note_list.dart';
import '../components/pagination_controls.dart';
import '../../dependency_injection.dart';
import '../account/user_session.dart';
import '../components/tag_cloud.dart';
import '../new_note/new_note.dart';
import 'home_page_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomePageController _homePageController;
  int currentPageNumber = 1;
  bool showPageSelector = false;

  bool get isFirstPage => currentPageNumber == 1;

  bool get isLastPage => currentPageNumber == _homePageController.totalPages;

  @override
  void initState() {
    super.initState();
    _homePageController = locator<HomePageController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navigateToPage(currentPageNumber);
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

  Future<void> _showTagInputDialog() async {
    final navigator = Navigator.of(context);
    String? newTag = await Util.showInputDialog(context, 'Enter a tag', 'such as hello');

    if (newTag != null) {
      if (newTag.startsWith('#')) {
        newTag = newTag.replaceAll('#', '');
      }
      newTag = newTag.trim();
      if (newTag.isNotEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => TagNotes(tag: newTag!, myNotesOnly: false),
          ),
        );
      }
    }
  }

  void _showTagDiagram(BuildContext context, Map<String, int> tagData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tag Cloud'),
          content: SingleChildScrollView(
            child: TagCloud(
              tagData: tagData,
              onTagTap: (tag) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagNotes(tag: tag, myNotesOnly: false),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    UserSession().isDesktop = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showTagInputDialog,
          onLongPress: () async {
            var tagData = await _homePageController.loadTagCloud(context);
            if (!mounted) return;
            _showTagDiagram(context, tagData);
          },
          child: const Text('My Notes'),
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
      icon: const Icon(Icons.edit),
      onPressed: () async {
        final scaffoldContext = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
              onNoteSaved: (note) async {
                navigator.pop();
                if (isFirstPage) {
                  await refreshPage();
                  return;
                }
                scaffoldContext.showSnackBar(
                  SnackBar(
                    content: const Text('Successfully saved. Click here to view.'),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'View',
                      onPressed: () async {
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (context) => NoteDetail(note: note),
                          ),
                        );
                      },
                    ),
                  ),
                );
                return;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_homePageController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homePageController.notes.isEmpty) {
      return const Center(child: Text('No notes available. Create a new note to get started.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NoteList(
            notes: _homePageController.notes,
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
            onTagTap: (note, tag) => NoteEventHandler.onTagTap(context, note, tag),
            onRefresh: () async => await navigateToPage(currentPageNumber),
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
