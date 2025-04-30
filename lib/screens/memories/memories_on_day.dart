import 'package:flutter/material.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:intl/intl.dart';

import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../components/note_list_item.dart';
import '../components/note_list.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../services/notes_services.dart';
import '../new_note/new_note.dart';
import '../note_detail/note_detail.dart';
import 'memories_on_day_controller.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

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
  late List<Note> _notes;
  late MemoriesOnDayController _controller;
  late TagCloudController _tagCloudController;

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

  @override
  void initState() {
    _controller =
        MemoriesOnDayController(notesService: locator<NotesService>());
    _tagCloudController = locator<TagCloudController>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      UserSession.routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
  }

  @override
  void didPopNext() {
    // No need to call setState here just because a route was popped.
    // Refresh should happen based on actual data changes if necessary.
  }

  @override
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: TappableAppBarTitle(
          title: DateFormat('EEE, MMM d, yyyy').format(widget.date),
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            var tagData = await _tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(context, tagData);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousDay,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextDay,
          ),
        ],
      ),
      body: FutureBuilder<NotesResult>(
        future: _controller.fetchMemories(widget.date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _notes = snapshot.data!.notes;
            return Stack(
              children: [
                NoteList(
                  notes: _notes,
                  showDateHeader: false,
                  showDate: false,
                  onTap: (note) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetail(note: note),
                      ),
                    );
                  },
                  onDoubleTap: (note) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NoteDetail(note: note, enterEditing: true),
                      ),
                    );
                  },
                  onTagTap: (note, tag) =>
                      NavigationHelper.onTagTap(context, note, tag),
                  onDelete: (note) async {
                    await _controller.deleteNote(context, note.id);
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
                        // final navigator = Navigator.of(context); // No longer needed here
                        // Await the result of pushing the NewNote screen
                        final bool? savedSuccessfully =
                            await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewNote(
                              date: widget.date,
                              isPrivate: true,
                              // onNoteSaved removed
                            ),
                          ),
                        );
                        // If savedSuccessfully is true (or not null and true), trigger a rebuild
                        if (savedSuccessfully ?? false) {
                          // Use ?? false for null safety
                          // Calling setState will cause the FutureBuilder to re-fetch data
                          if (mounted) {
                            setState(() {});
                          }
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No notes found on this day.'));
          }
        },
      ),
    );
  }
}
