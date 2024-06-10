import 'package:flutter/material.dart';
import 'package:happy_notes/screens/home_page_controller.dart';
import 'package:happy_notes/screens/note_detail.dart';
import '../dependency_injection.dart';
import '../services/notes_services.dart';
import '../components/note_list.dart';
import '../components/pagination_controls.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late HomePageController _homePageController;
  int currentPageNumber = 1;

  bool get isFirstPage => currentPageNumber == 1;

  @override
  void initState() {
    super.initState();
    _homePageController = HomePageController(locator<NotesService>());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      body: _buildBody(),
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
            onTap: (noteId) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(noteId: noteId),
                ),
              );
              await navigateToPage(currentPageNumber);
            },
            onDoubleTap: (noteId) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(noteId: noteId, enterEditing: true),
                ),
              );
              navigateToPage(currentPageNumber);
            },
            onRefresh: () async => await navigateToPage(currentPageNumber),
          ),
        ),
        if (_homePageController.totalPages > 1)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _homePageController.totalPages,
            onPreviousPage: () => navigateToPage(currentPageNumber - 1),
            onNextPage: () => navigateToPage(currentPageNumber + 1),
          ),
      ],
    );
  }
}
