import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../components/controllers/tag_cloud_controller.dart';
import '../../providers/memories_provider.dart';
import '../../providers/note_list_provider.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/util.dart';
import '../account/user_session.dart';
import '../../entities/note.dart';
import '../new_note/new_note.dart';
import '../note_detail/note_detail.dart';
import '../components/tappable_app_bar_title.dart';
import '../components/note_list/note_list.dart';
import '../components/note_list/note_list_callbacks.dart';

class MemoriesOnDay extends StatefulWidget {
  final DateTime date;

  const MemoriesOnDay({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  MemoriesOnDayState createState() => MemoriesOnDayState();
}

class MemoriesOnDayState extends State<MemoriesOnDay> with RouteAware {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      UserSession.routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Auto-load memories for the date when widget initializes
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final provider = context.read<MemoriesProvider>();
        final dateString = DateFormat('yyyyMMdd').format(widget.date);
        await provider.setCurrentDate(dateString);
        await provider.loadMemoriesForDate(dateString);
      });
    }
  }

  @override
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _navigateToDate(DateTime date) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MemoriesOnDay(date: date),
      ),
    );
  }

  void _goToPreviousDay() {
    final previousDay = widget.date.subtract(const Duration(days: 1));
    _navigateToDate(previousDay);
  }

  void _goToNextDay() {
    final nextDay = widget.date.add(const Duration(days: 1));
    _navigateToDate(nextDay);
  }

  void _onNoteSaved(Note savedNote) {
    final provider = context.read<MemoriesProvider>();
    final dateString = DateFormat('yyyyMMdd').format(widget.date);
    provider.addMemoryToDate(dateString, savedNote);
  }

  void _onNoteUpdated(Note updatedNote) {
    final provider = context.read<MemoriesProvider>();
    final dateString = DateFormat('yyyyMMdd').format(widget.date);
    provider.updateMemoryForDate(dateString, updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TappableAppBarTitle(
          title: 'Memories',
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            final navigator = Navigator.of(context);
            final tagCloudController = TagCloudController();
            final tagData = await tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousDay,
            tooltip: 'Previous Day',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextDay,
            tooltip: 'Next Day',
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<MemoriesProvider>(
            builder: (context, provider, child) {
              final dateString = DateFormat('yyyyMMdd').format(widget.date);
              final isLoading = provider.isLoadingForDate(dateString);
              final notes = provider.memoriesOnDate(dateString);
              final error = provider.getErrorForDate(dateString);

              return _buildBody(isLoading, notes, error);
            },
          ),
          // Add Note Button
          Positioned(
            right: 0,
            bottom: 16,
            child: Opacity(
              opacity: 0.5,
              child: FloatingActionButton(
                onPressed: () async {
                  final newNote = await Navigator.push<Note>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewNote(isPrivate: false, date: widget.date),
                    ),
                  );
                  if (newNote != null) {
                    _onNoteSaved(newNote);
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isLoading, List<Note> notes, String? error) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () {
                final provider = context.read<MemoriesProvider>();
                final dateString = DateFormat('yyyyMMdd').format(widget.date);
                provider.loadMemoriesForDate(dateString, forceRefresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No memories on ${DateFormat('MMM dd, yyyy').format(widget.date)}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final newNote = await Navigator.push<Note>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewNote(isPrivate: false, date: widget.date),
                  ),
                );
                if (newNote != null) {
                  _onNoteSaved(newNote);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Memory'),
            ),
          ],
        ),
      );
    }

    // Group notes by date for consistent display
    final groupedNotes = <String, List<Note>>{};
    for (final note in notes) {
      final dateKey = note.createdDate;
      groupedNotes[dateKey] = groupedNotes[dateKey] ?? [];
      groupedNotes[dateKey]!.add(note);
    }

    // Wrap NoteList with Provider to expose MemoriesProvider as NoteListProvider
    final memoriesProvider = context.read<MemoriesProvider>();

    return ChangeNotifierProvider<NoteListProvider>.value(
      value: memoriesProvider,
      child: NoteList(
        groupedNotes: groupedNotes,
        showDateHeader: true,
        callbacks: ListItemCallbacks<Note>(
          onTap: (note) async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetail(note: note),
              ),
            );
            // No need to reload - NoteDetail in view mode doesn't change data
          },
          onDoubleTap: (note) async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetail(
                  note: note,
                  enterEditing: note.userId == UserSession().id,
                  onNoteSaved: _onNoteUpdated,
                ),
              ),
            );
            // The callback will handle cache updates automatically
          },
          onDelete: (note) async {
            final provider = context.read<MemoriesProvider>();
            final result = await provider.deleteNote(note.id);
            if (!result.isSuccess && mounted) {
              Util.showError(ScaffoldMessenger.of(context), result.errorMessage!);
            }
          },
        ),
        noteCallbacks: NoteListCallbacks(
          onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
          onRefresh: () async {
            final provider = context.read<MemoriesProvider>();
            final dateString = DateFormat('yyyyMMdd').format(widget.date);
            await provider.loadMemoriesForDate(dateString, forceRefresh: true);
          },
        ),
        config: const ListItemConfig(
          showDate: false,
          showAuthor: false,
          showRestoreButton: false,
          enableDismiss: true,
        ),
      ),
    );
  }
}
