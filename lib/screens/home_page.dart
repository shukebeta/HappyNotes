import 'package:happy_notes/screens/home_page_controller.dart';
import 'package:happy_notes/screens/note_detail.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';
import '../services/notes_services.dart';
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
                        MaterialPageRoute(builder: (context) => const NewNote(
                          isPrivate: false,
                        )),
                      );
                      if (result != null && result['noteId'] != null) {
                        scaffoldContext.showSnackBar(
                          SnackBar(
                            content: const Text('Successfully saved. Click here to view.'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'View',
                              onPressed: () async {
                                await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => NoteDetail(noteId: result['noteId'])),
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
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _homePageController.notes.isEmpty
                      ? const CircularProgressIndicator()
                      : Expanded(
                    child: ListView.builder(
                      itemCount: _homePageController.notes.length,
                      itemBuilder: (context, index) {
                        final note = _homePageController.notes[index];
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: note.isLong ? '${note.content}...   ' : note.content,
                                    style: TextStyle(
                                      fontWeight: note.isPrivate ? FontWeight.w100 : FontWeight.normal,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                    children: note.isLong
                                        ? [
                                      const TextSpan(
                                        text: 'more',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      )
                                    ]
                                        : [],
                                  ),
                                ),
                              ),
                              if (note.isPrivate)
                                const Icon(
                                  Icons.lock,
                                  size: 16.0,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                          subtitle: Text(
                            DateTime.fromMillisecondsSinceEpoch(note.createAt * 1000).toString(),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteDetail(noteId: note.id),
                              ),
                            );
                            navigateToPage(_homePageController.currentPageNumber);
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _homePageController.currentPageNumber > 1
                            ? () => navigateToPage(_homePageController.currentPageNumber - 1)
                            : null,
                        child: const Text('Previous Page'),
                      ),
                      const SizedBox(width: 20),
                      Text('Page ${_homePageController.currentPageNumber} of ${_homePageController.totalPages}'),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _homePageController.currentPageNumber < _homePageController.totalPages
                            ? () => navigateToPage( _homePageController.currentPageNumber + 1)
                            : null,
                        child: const Text('Next Page'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
