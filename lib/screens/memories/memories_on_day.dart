import 'package:flutter/material.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:intl/intl.dart';

import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../components/note_list_item.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../services/notes_services.dart';
import '../new_note/new_note.dart';
import '../note_detail/note_detail.dart';
import 'memories_on_day_controller.dart';

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
    _controller = MemoriesOnDayController(notesService: locator<NotesService>());
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      UserSession.routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
  }

  @override
  void didPopNext() {
    setState(() {});
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
        title: Text(DateFormat('EEE, MMM d, yyyy').format(widget.date)),
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
                ListView(
                  children: _notes.map((note) => NoteListItem(
                    note: note,
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
                          builder: (context) => NoteDetail(note: note, enterEditing: true),
                        ),
                      );
                    },
                    onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
                    onDelete: (note) async {
                      await _controller.deleteNote(context, note.id);
                    },
                  )).toList(),
                ),
                // Add Note Button
                Positioned(
                  right: 0,
                  bottom: 16,
                  child: Opacity(
                    opacity: 0.5,
                    child: FloatingActionButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final newNote = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewNote(
                              date: widget.date,
                              isPrivate: true,
                              onNoteSaved: (note) async {
                                navigator.pop();
                              },
                            ),
                          ),
                        );
                        if (newNote != null) {
                          setState(() {});
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
