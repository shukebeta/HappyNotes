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
                title: const Text('Home Page'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context); // Capture the context
                      // Navigate to the write note screen and wait for result
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewNote()),
                      );

                      // Check if a note was saved
                      if (result != null && result['noteId'] != null) {
                        scaffoldContext.showSnackBar(
                          SnackBar(
                            content: const Text('Successfully saved. Click here to view.'),
                            duration: const Duration(hours: 1),
                            action: SnackBarAction(
                              label: 'View',
                              onPressed: () {
                                // Navigate to the note details page or perform the view action
                                // Navigator.push(context, ...);
                              },
                            ),
                          ),
                        );
                        // Reload the notes
                        // loadNotes(notesPerPage, currentPage);
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
                                title: Text(note.content),
                                subtitle: Text(
                                    DateTime.fromMillisecondsSinceEpoch(
                                            note.createAt * 1000)
                                        .toString()),
                              );
                            },
                          ),
                        ),
                  // Pagination buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 1
                            ? () =>
                                navigateToPage(notesPerPage, currentPage - 1)
                            : null,
                        child: const Text('Previous Page'),
                      ),
                      const SizedBox(width: 20),
                      Text('Page $currentPage of $totalPages'),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: currentPage < totalPages
                            ? () =>
                                navigateToPage(notesPerPage, currentPage + 1)
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
