import 'package:flutter/material.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';

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
  bool _isPurging = false;

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
          _buildPurgeDeletedButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _trashedNotes.isEmpty
                ? const Center(child: Text('No notes in the trash bin.'))
                : ListView.builder(
                    itemCount: _trashedNotes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: _buildNoteContent(_trashedNotes[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'Restore note',
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

  Widget _buildNoteContent(Note note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.content.length > 100 ? '${note.content.substring(0, 100)}...' : note.content,
        ),
        if (note.isLong)
          TextButton(
            onPressed: () async {
              try {
                Note fullNote = await _notesService.get(note.id, includeDeleted: true);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NoteDetail(note: fullNote)),
                );
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('View more'),
          ),
        if (note.deletedDate != null)
          Text(
            'Deleted on: ${note.deletedDate}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildPurgeDeletedButton() {
    return IconButton(
      icon: _isPurging ? const Icon(Icons.hourglass_top) : const Icon(Icons.delete_forever),
      onPressed: _isPurging
          ? null
          : () async {
              setState(() {
                _isPurging = true;
              });
              try {
                await _notesService.purgeDeleted();
              } catch (e) {
                // Handle error
              } finally {
                if (mounted) {
                  setState(() {
                    _isPurging = false;
                  });
                  _fetchTrashedNotes();
                }
              }
            },
    );
  }
}
