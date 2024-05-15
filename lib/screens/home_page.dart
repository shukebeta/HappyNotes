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
  //initial value is set to 1
  int totalNotes = 1;

  // Calculate total number of pages based on notes count and notes per page
  int get totalPages => (totalNotes / notesPerPage).floor() + 1;

  @override
  void initState() {
    super.initState();
    // Load notes from the server when the widget is first initialized
    loadNotes(notesPerPage, currentPage);
  }

  // Function to load notes from the server
  Future<void> loadNotes(int pageSize, int pageNumber) async {
    try {
      // Call NotesService.latest method to fetch notes
      var apiResult = await NotesService.latest( // replace NotesService.latest with the appropriate method
        pageSize,
        pageNumber,
      );
      totalNotes = apiResult['totalCount'];
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
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return ListTile(
                          title: Text(note.content),
                          subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
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
                            ? () => navigateToPage(notesPerPage, currentPage - 1)
                            : null,
                        child: Text('Previous Page'),
                      ),
                      SizedBox(width: 20),
                      Text('Page $currentPage of $totalPages'),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: currentPage < totalPages
                            ? () => navigateToPage(notesPerPage, currentPage + 1)
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
  void navigateToPage(int pageSize, int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= totalPages) {
      setState(() {
        currentPage = pageNumber;
      });
      await loadNotes(pageSize, pageNumber);
    }
  }
}
