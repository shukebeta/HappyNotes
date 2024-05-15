import 'package:HappyNotes/screens/write-note.dart';
import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/notes_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _HomePageState extends State<HomePage> {
  List<Note> notes = []; // List to hold notes fetched from the server

  // Pagination variables
  final int notesPerPage = 5; // Number of notes per page
  int currentPage = 1; // Current page number

  // Calculate total number of pages based on notes count and notes per page
  int get totalPages => (notes.length / notesPerPage).ceil();

  // Get notes for the current page
  List<Note> getNotesForPage(int page) {
    final startIndex = (page - 1) * notesPerPage;
    final endIndex = startIndex + notesPerPage;
    return notes.sublist(startIndex, endIndex.clamp(0, notes.length));
  }

  @override
  void initState() {
    super.initState();
    // Load notes from the server when the widget is first initialized
    loadNotes();
  }

  // Function to load notes from the server
  void loadNotes() async {
    try {
      // Call NotesService.latest method to fetch notes
      var apiResult = await NotesService.latest( // replace NotesService.latest with the appropriate method
        notesPerPage,
        1,
      );
      List<dynamic> fetchedNotesData = apiResult['dataList']; // Extract the list of notes data from the response
      List<Note> fetchedNotes = fetchedNotesData.map((json) => Note.fromJson(json)).toList();
      setState(() {
        notes = fetchedNotes; // Update the notes list with the fetched notes
      });
    } catch (error) {
      // Handle any errors that occur during the fetch operation
      print('Error loading notes: $error');
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
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to the write note screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WriteNote()),
                      );
                    },
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // List of notes
                  Expanded(
                    child: ListView.builder(
                      itemCount: getNotesForPage(currentPage).length,
                      itemBuilder: (context, index) {
                        final note = getNotesForPage(currentPage)[index];
                        return ListTile(
                          title: Text(note.content),
                          subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
                                  note.createAt)
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
                            ? () => navigateToPage(currentPage - 1)
                            : null,
                        child: Text('Previous Page'),
                      ),
                      SizedBox(width: 20),
                      Text('Page $currentPage of $totalPages'),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: currentPage < totalPages
                            ? () => navigateToPage(currentPage + 1)
                            : null,
                        child: Text('Next Page'),
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

// Function to navigate to a specific page
  void navigateToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
    }
  }
}
