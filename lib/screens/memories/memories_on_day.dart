import 'package:flutter/material.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:intl/intl.dart';

import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../components/note_list.dart';
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
        title: Text(DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
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
                  showDate: false,
                  onRefresh: () async {
                    setState(() {});
                  },
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
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);
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
                        setState(() {}); // Refresh the list when a new note is added
                      }
                    },
                    child: const Icon(Icons.add),
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
