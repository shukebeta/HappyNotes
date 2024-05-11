import 'package:HappyNotes/screens/write-note.dart';
import 'package:flutter/material.dart';

import '../models/note_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _HomePageState extends State<HomePage> {
// Mock data for notes
  final List<Note> mockNotes = [
    Note(
      id: 1,
      content: 'This is note 1',
      isPrivate: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    Note(
      id: 2,
      content: 'This is note 2',
      isPrivate: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    Note(
      id: 3,
      content: 'This is note 3',
      isPrivate: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    // Add more mock notes as needed
    Note(
      id: 4,
      content: 'This is note 4',
      isPrivate: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    Note(
      id: 5,
      content: 'This is note 5',
      isPrivate: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    Note(
      id: 6,
      content: 'This is note 6',
      isPrivate: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

  // Pagination variables
  final int notesPerPage = 5; // Number of notes per page
  int currentPage = 1; // Current page number

  // Calculate total number of pages based on notes count and notes per page
  int get totalPages => (mockNotes.length / notesPerPage).ceil();

  // Get notes for the current page
  // Get notes for the current page
  List<Note> getNotesForPage(int page) {
    final startIndex = (page - 1) * notesPerPage;
    final endIndex = startIndex + notesPerPage;
    return mockNotes.sublist(startIndex, endIndex.clamp(0, mockNotes.length));
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
                                  note.createdAt)
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
