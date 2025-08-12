import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/services/dialog_services.dart';
import '../components/pagination_controls.dart';
import '../components/note_list/note_list.dart';
import '../components/note_list/note_list_callbacks.dart';
import '../account/user_session.dart';
import '../components/floating_pagination.dart';
import '../../providers/trash_provider.dart';

class TrashBinPage extends StatefulWidget {
  const TrashBinPage({super.key});

  @override
  TrashBinPageState createState() => TrashBinPageState();
}

class TrashBinPageState extends State<TrashBinPage> {
  int currentPageNumber = 1;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final trashProvider = context.read<TrashProvider>();
        trashProvider.navigateToPage(currentPageNumber);
      });
    }
  }

  Future<bool> navigateToPage(int pageNumber) async {
    final trashProvider = context.read<TrashProvider>();
    if (pageNumber >= 1 && pageNumber <= trashProvider.totalPages) {
      await trashProvider.navigateToPage(pageNumber);
      setState(() {
        currentPageNumber = pageNumber;
      });
      return true;
    }
    return false;
  }

  Future<bool> refreshPage() async {
    return await navigateToPage(currentPageNumber);
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
                Consumer<TrashProvider>(
                  builder: (context, trashProvider, child) {
                    if (trashProvider.totalPages > 1) {
                      return PaginationControls(
                        currentPage: currentPageNumber,
                        totalPages: trashProvider.totalPages,
                        navigateToPage: navigateToPage,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            )
          : Stack(
              children: [
                _buildBody(),
                Consumer<TrashProvider>(
                  builder: (context, trashProvider, child) {
                    if (trashProvider.totalPages > 1) {
                      return FloatingPagination(
                        currentPage: currentPageNumber,
                        totalPages: trashProvider.totalPages,
                        navigateToPage: navigateToPage,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildPurgeDeletedButton() {
    return Consumer<TrashProvider>(
      builder: (context, trashProvider, child) {
        return IconButton(
          onPressed: trashProvider.isPurging
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final confirmed = await DialogService.showConfirmDialog(
                    context,
                    title: 'Are you sure?',
                    text: 'This will permanently delete all notes in the trash. This action cannot be undone.',
                  );
                  if (confirmed == true && mounted) {
                    final success = await trashProvider.purgeDeleted();
                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('All deleted notes have been purged.')),
                      );
                    }
                  }
                },
          icon: trashProvider.isPurging
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever),
          tooltip: 'Purge All Deleted Notes',
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<TrashProvider>(
      builder: (context, trashProvider, child) {
        if (trashProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (trashProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${trashProvider.error}'),
                ElevatedButton(
                  onPressed: () => navigateToPage(currentPageNumber),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (trashProvider.notes.isEmpty) {
          return const Center(
            child: Text('Trash is empty'),
          );
        }

        return NoteList(
          groupedNotes: trashProvider.groupedNotes,
          showDateHeader: true,
          callbacks: ListItemCallbacks<Note>(
            onTap: (note) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(note: note),
                ),
              );
              await refreshPage();
            },
            onDoubleTap: (note) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(note: note),
                ),
              );
              await refreshPage();
            },
            onDelete: (note) async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmed = await DialogService.showConfirmDialog(
                context,
                title: 'Permanently Delete Note?',
                text: 'This will permanently delete this note. This action cannot be undone.',
              );
              if (confirmed == true && mounted) {
                // For now, we'll just show a message since permanent delete isn't implemented
                messenger.showSnackBar(
                  const SnackBar(content: Text('Permanent delete not implemented')),
                );
              }
            },
            onRestore: (note) async {
              final messenger = ScaffoldMessenger.of(context);
              final success = await trashProvider.undeleteNote(note.id);
              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Note restored successfully')),
                );
              } else if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to restore note')),
                );
              }
            },
          ),
          noteCallbacks: NoteListCallbacks(
            onRefresh: () async => await refreshPage(),
          ),
          config: const ListItemConfig(
            showDate: false,
            showAuthor: false,
            showRestoreButton: true,
            enableDismiss: false,
          ),
        );
      },
    );
  }
}