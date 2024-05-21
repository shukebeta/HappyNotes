import 'package:happy_notes/screens/note_detail.dart';
import 'package:flutter/material.dart';

import '../entities/note.dart';
import '../services/notes_services.dart';
import '../utils/util.dart';
import 'new_note.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomePageState extends State<HomePage> {
  List<Note> notes = []; // List to hold notes fetched from the server

  // Pagination variables
  final int notesPerPage = 5; // Number of notes per page
  int currentPage = 1; // Current page number
  //initial value is set to 1
  int totalNotes = 1;

  // Calculate total number of pages based on notes count and notes per page
  int get totalPages => (totalNotes / notesPerPage).ceil();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navigateToPage(notesPerPage, 1);
  }

  // Function to navigate to a specific page
  void navigateToPage(int pageSize, int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= totalPages) {
      await loadNotes(pageSize, pageNumber);
    }
  }

  // Function to load notes from the server
  Future<void> loadNotes(int pageSize, int pageNumber) async {
    final scaffoldContext = ScaffoldMessenger.of(context); // Capture the context
    try {
      var result = await NotesService.myLatest(pageSize, pageNumber);
      setState(() {
        totalNotes = result.totalNotes;
        notes = result.notes;
        currentPage = pageNumber;
      });
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
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
                    icon: const Icon(Icons.edit), // write a new note
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context); // Capture the context
                      // Navigate to the write note screen and wait for result
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewNote(isPrivate: false,)),
                      );

                      // Check if a note was saved
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
                        // If it is the first page, Reload the notes
                        if (currentPage == 1) {
                          loadNotes(notesPerPage, currentPage);
                        }
                      }
                    },
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  notes.isEmpty
                      ? const CircularProgressIndicator()
                  // List of notes
                      : Expanded(
                    child: ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: note.isLong ? '${note.content}...   '
                                        : note.content,
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
                            // Reload notes after returning from detail page
                            loadNotes(notesPerPage, currentPage);
                          },
                        );
                      },
                    ),
                  ),
                  // Pagination buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 1 ? () => navigateToPage(notesPerPage, currentPage - 1) : null,
                        child: const Text('Previous Page'),
                      ),
                      const SizedBox(width: 20),
                      Text('Page $currentPage of $totalPages'),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: currentPage < totalPages ? () => navigateToPage(notesPerPage, currentPage + 1) : null,
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
