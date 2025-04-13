import 'package:flutter/material.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/screens/trash_bin/trash_bin_controller.dart';
import '../components/pagination_controls.dart';
import '../components/note_list_item.dart';

class TrashBinPage extends StatefulWidget {
  const TrashBinPage({super.key});

  @override
  TrashBinPageState createState() => TrashBinPageState();
}

class TrashBinPageState extends State<TrashBinPage> {
  final TrashBinController _controller = TrashBinController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _controller.fetchTrashedNotes();
    setState(() {});
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
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.trashedNotes.isEmpty
                    ? const Center(child: Text('No notes in the trash bin.'))
                    : RefreshIndicator(
                        onRefresh: _controller.fetchTrashedNotes,
                        child: ListView(
                          children: _controller.trashedNotes.map((note) {
                            return NoteListItem(
                              note: note,
                              onTap: (note) async {
                                try {
                                  Note fullNote = await _controller.getNote(note.id);
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
                                  await _controller.undeleteNote(note.id);
                                  setState(() {});
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
          if (_controller.totalPages > 1 && !_controller.isLoading)
            PaginationControls(
              currentPage: _controller.currentPageNumber,
              totalPages: _controller.totalPages,
              navigateToPage: (pageNumber) async {
                await _controller.navigateToPage(pageNumber);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPurgeDeletedButton() {
    return IconButton(
      icon: _controller.isPurging ? const Icon(Icons.hourglass_top) : const Icon(Icons.delete_forever),
      onPressed: _controller.isPurging
          ? null
          : () async {
              await _controller.purgeDeleted();
              setState(() {});
            },
    );
  }
}
