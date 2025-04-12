import 'package:flutter/material.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/entities/note.dart';

class TrashBinPage extends StatefulWidget {
  const TrashBinPage({super.key});

  @override
  TrashBinPageState createState() => TrashBinPageState();
}

class TrashBinPageState extends State<TrashBinPage> {
  final NotesService _notesService = locator<NotesService>();
  List<Note> _trashedNotes = [];
  int _currentPageNumber = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchTrashedNotes();
  }

  Future<void> _fetchTrashedNotes() async {
    try {
      var result = await _notesService.latestDeleted(10, _currentPageNumber);
      setState(() {
        _trashedNotes = result.notes;
        _totalPages = (result.totalNotes / 10).ceil();
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              try {
                await _notesService.purgeDeleted();
                _fetchTrashedNotes();
              } catch (e) {
                // Handle error
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _trashedNotes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_trashedNotes[index].content),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore),
                    onPressed: () async {
                      try {
                        await _notesService.undelete(_trashedNotes[index].id);
                        _fetchTrashedNotes();
                      } catch (e) {
                        // Handle error
                      }
                    },
                  ),
                );
              },
            ),
          ),
          if (_totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentPageNumber > 1
                      ? () async {
                          setState(() {
                            _currentPageNumber--;
                          });
                          await _fetchTrashedNotes();
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                Text('Page: $_currentPageNumber/$_totalPages'),
                ElevatedButton(
                  onPressed: _currentPageNumber < _totalPages
                      ? () async {
                          setState(() {
                            _currentPageNumber++;
                          });
                          await _fetchTrashedNotes();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
