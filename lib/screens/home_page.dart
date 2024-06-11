import 'package:flutter/material.dart';
import 'package:happy_notes/screens/home_page_controller.dart';
import 'package:happy_notes/screens/note_detail.dart';
import '../dependency_injection.dart';
import '../services/notes_services.dart';
import '../components/note_list.dart';
import '../components/pagination_controls.dart';
import '../utils/util.dart';
import 'new_note.dart';

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
    var isDesktop = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(title: const Text('My Notes'), actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final scaffoldContext = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewNote(
                  isPrivate: false, // this entry is always for public note
                  onNoteSaved: (int? noteId) async {
                    if (noteId == null) {
                      Util.showError(scaffoldContext,
                          "Something is wrong when saving the note");
                      return;
                    }
                    navigator.pop();
                    if (isFirstPage) {
                      await refreshPage();
                      return;
                    }
                    scaffoldContext.showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Successfully saved. Click here to view.'),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'View',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NoteDetail(noteId: noteId),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ]),
      body: Stack(
        children: [
          _buildBody(isDesktop),
          if (_homePageController.totalPages > 1 && !isDesktop)
            _buildFloatingPagination(),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
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
                  builder: (context) =>
                      NoteDetail(noteId: noteId, enterEditing: true),
                ),
              );
              navigateToPage(currentPageNumber);
            },
            onRefresh: () async => await navigateToPage(currentPageNumber),
          ),
        ),
        if (_homePageController.totalPages > 1 && isDesktop)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _homePageController.totalPages,
            onPreviousPage: () => navigateToPage(currentPageNumber - 1),
            onNextPage: () => navigateToPage(currentPageNumber + 1),
          ),
      ],
    );
  }

  Widget _buildFloatingPagination() {
    return Positioned(
      right: 16,
      top: 100,
      bottom: 100,
      child: showPageSelector
          ? _buildPageSelector()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: () {
                    setState(() {
                      showPageSelector = true;
                    });
                  },
                  child: FloatingActionButton(
                    heroTag: 'prevPage',
                    mini: true,
                    onPressed: isFirstPage
                        ? null
                        : () => navigateToPage(currentPageNumber - 1),
                    backgroundColor: isFirstPage
                        ? Colors.grey.shade400
                        : const Color(0xFFEBDDFF),
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),
                const SizedBox(height: 16),
                Text('$currentPageNumber'),
                const SizedBox(height: 16),
                GestureDetector(
                  onLongPress: () {
                    setState(() {
                      showPageSelector = true;
                    });
                  },
                  child: FloatingActionButton(
                    heroTag: 'nextPage',
                    mini: true,
                    onPressed: isLastPage
                        ? null
                        : () => navigateToPage(currentPageNumber + 1),
                    backgroundColor: isLastPage
                        ? Colors.grey.shade400
                        : const Color(0xFFEBDDFF),
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPageSelector() {
    final TextEditingController pageController = TextEditingController();
    final FocusNode pageFocusNode = FocusNode();

    return GestureDetector(
      onTap: () {
        setState(() {
          showPageSelector = false;
        });
      },
      child: Center(
        child: Material(
          // Ensures the container has a proper layout
          color: Colors.transparent, // Makes sure we see the selector clearly
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 300, // Set max width for the selector container
              maxHeight: 200, // Set max height for the selector container
            ),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pageController,
                  focusNode: pageFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'Enter a page number: 1 ~ ${_homePageController.totalPages}',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final page = int.tryParse(pageController.text);
                    if (page != null &&
                        page > 0 &&
                        page <= _homePageController.totalPages) {
                      navigateToPage(page);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid page number')),
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
