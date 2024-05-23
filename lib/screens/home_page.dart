import 'package:flutter/material.dart';
import 'package:happy_notes/screens/home_page_controller.dart';
import 'package:happy_notes/screens/note_detail.dart';
import '../dependency_injection.dart';
import '../services/notes_services.dart';
import 'components/note_list.dart';
import 'components/pagination_controls.dart';
import 'new_note.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomePageState extends State<HomePage> {
  late HomePageController _homePageController;

  @override
  void initState() {
    super.initState();
    _homePageController = HomePageController(locator<NotesService>());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navigateToPage(1);
  }

  void navigateToPage(int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= _homePageController.totalPages) {
      await _homePageController.loadNotes(context, pageNumber);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('My Notes'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewNote(
                            isPrivate: false,
                          ),
                        ),
                      );
                      if (result != null && result['noteId'] != null) {
                        scaffoldContext.showSnackBar(
                          SnackBar(
                            content: const Text('Successfully saved. Click here to view.'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'View',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NoteDetail(noteId: result['noteId']),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                        if (_homePageController.isFirstPage) {
                          navigateToPage(_homePageController.currentPageNumber);
                        }
                      }
                    },
                  ),
                ],
              ),
              body: _buildBody(),
            );
          },
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
            onNoteTap: (noteId) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(noteId: noteId),
                ),
              );
              navigateToPage(_homePageController.currentPageNumber);
            },
          ),
        ),
        if (_homePageController.notes.isNotEmpty)
          PaginationControls(
            currentPage: _homePageController.currentPageNumber,
            totalPages: _homePageController.totalPages,
            onPreviousPage: () => navigateToPage(_homePageController.currentPageNumber - 1),
            onNextPage: () => navigateToPage(_homePageController.currentPageNumber + 1),
          ),
      ],
    );
  }
}
