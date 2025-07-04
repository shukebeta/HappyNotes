import 'package:flutter/material.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/screens/trash_bin/trash_bin_controller.dart';
import 'package:happy_notes/services/dialog_services.dart';
import '../components/pagination_controls.dart';
import '../components/note_list/note-list.dart';
import '../components/note_list/note-list-item.dart';
import '../account/user_session.dart';
import '../components/floating_pagination.dart';

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
      body: UserSession().isDesktop
          ? Column(
              children: [
                Expanded(
                  child: _buildBody(),
                ),
                if (_controller.totalPages > 1)
                  PaginationControls(
                    currentPage: _controller.currentPageNumber,
                    totalPages: _controller.totalPages,
                    navigateToPage: (pageNumber) async {
                      await _controller.navigateToPage(pageNumber);
                      setState(() {});
                    },
                  ),
              ],
            )
          : Stack(
              children: [
                _buildBody(),
                if (_controller.totalPages > 1)
                  FloatingPagination(
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

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.trashedNotes.isEmpty) {
      return const Center(child: Text('No notes in the trash bin.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _controller.fetchTrashedNotes();
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: _controller.trashedNotes.map((note) {
            return NoteListItem(
              note: note,
              callbacks: ListItemCallbacks<Note>(
                onTap: (note) async {
                  try {
                    Note fullNote = await _controller.getNote(note.id);
                    final bool? needRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetail(note: fullNote),
                      ),
                    );

                    if (needRefresh ?? false) {
                      await _controller.fetchTrashedNotes();
                      setState(() {});
                    }
                  } catch (e) {
                    // Handle error
                  }
                },
                onRestore: (note) async {
                  try {
                    await _controller.undeleteNote(note.id);
                    setState(() {});
                  } catch (e) {
                    // Handle error
                  }
                },
              ),
              config: const ListItemConfig(
                showDate: true,
                showAuthor: false,
                showRestoreButton: true,
                enableDismiss: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPurgeDeletedButton() {
    return IconButton(
      icon: _controller.isPurging ? const Icon(Icons.hourglass_top) : const Icon(Icons.delete_forever),
      onPressed: _controller.isPurging
          ? null
          : () async {
              final bool? shouldPurge = await DialogService.showConfirmDialog(
                context,
                title: 'Empty Trash Bin',
                text: 'Are you sure you want to empty the trash bin? This action cannot be undone.',
                noText: 'Cancel',
                yesText: 'Empty',
              );

              if (shouldPurge ?? false) {
                await _controller.purgeDeleted();
                setState(() {});
              }
            },
    );
  }
}
