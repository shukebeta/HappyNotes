import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../components/controllers/tag_cloud_controller.dart';
import '../../providers/memories_provider.dart';
import '../../utils/navigation_helper.dart';
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
  List<Note> _notes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      UserSession.routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    _loadMemoriesForDate();
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

  Future<void> _loadMemoriesForDate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final memoriesProvider = context.read<MemoriesProvider>();
      final dateString = DateFormat('yyyyMMdd').format(widget.date);
      final result = await memoriesProvider.memoriesOn(dateString);

      if (mounted) {
        setState(() {
          _notes = result?.notes ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TappableAppBarTitle(
          title: 'Memories: ${DateFormat('MMM dd, yyyy').format(widget.date)}',
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
          _buildNewNoteButton(),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildNewNoteButton() {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NewNote(isPrivate: false),
          ),
        );
        // Refresh after adding new note
        await _loadMemoriesForDate();
      },
      tooltip: 'New Note',
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadMemoriesForDate,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No memories on ${DateFormat('MMM dd, yyyy').format(widget.date)}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewNote(isPrivate: false),
                  ),
                );
                await _loadMemoriesForDate();
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
    for (final note in _notes) {
      final dateKey = note.createdDate;
      groupedNotes[dateKey] = groupedNotes[dateKey] ?? [];
      groupedNotes[dateKey]!.add(note);
    }

    return NoteList(
      groupedNotes: groupedNotes,
      showDateHeader: true,
      callbacks: ListItemCallbacks<Note>(
        onTap: (note) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetail(note: note),
            ),
          );
          await _loadMemoriesForDate();
        },
        onDoubleTap: (note) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetail(
                note: note,
                enterEditing: note.userId == UserSession().id,
              ),
            ),
          );
          await _loadMemoriesForDate();
        },
        onDelete: (note) async {
          // Delete note through memories provider - it doesn't implement delete
          // So we'll show a message for now
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delete not available on memories page')),
          );
        },
      ),
      noteCallbacks: NoteListCallbacks(
        onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
        onRefresh: () async => await _loadMemoriesForDate(),
      ),
      config: const ListItemConfig(
        showDate: false,
        showAuthor: false,
        showRestoreButton: false,
        enableDismiss: false,
      ),
    );
  }
}