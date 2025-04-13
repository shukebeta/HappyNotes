import 'package:flutter/material.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../app_config.dart';
import 'components/pagination_controls.dart';
import 'components/note_list_item.dart';

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
      var result = await _notesService.latestDeleted(AppConfig.pageSize, _currentPageNumber);
      setState(() {
        _trashedNotes = result.notes;
        _totalPages = (result.totalNotes / AppConfig.pageSize).ceil();
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
                : RefreshIndicator(
                    onRefresh: _fetchTrashedNotes,
                    child: ListView(
                      children: _trashedNotes.map((note) {
                        return NoteListItem(
                          note: note,
                          onTap: (note) async {
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
                          onRestoreTap: (note) async {
                            try {
                              await _notesService.undelete(note.id);
                              _fetchTrashedNotes();
                            } catch (e) {
                              // Handle error
                            }
                          },
                          showDate: true,
                          showRestoreButton: true,
                        );
                      }).toList(),
                    ),
                  ),
          ),
          if (_totalPages > 1)
            PaginationControls(
              currentPage: _currentPageNumber,
              totalPages: _totalPages,
              navigateToPage: (pageNumber) async {
                setState(() {
                  _currentPageNumber = pageNumber;
                });
                await _fetchTrashedNotes();
              },
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
