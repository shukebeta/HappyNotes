import 'package:flutter/material.dart';
import 'package:happy_notes/results/notes_result.dart';
import 'package:intl/intl.dart';

import '../../components/note_list.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../services/notes_services.dart';
import '../note_detail.dart';
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
class MemoriesOnDayState extends State<MemoriesOnDay> {
  late Future<NotesResult> _notesFuture;
  late List<Note> _notes;
  late MemoriesOnDayController _controller;
  @override
  void initState() {
    super.initState();
    _controller = MemoriesOnDayController(notesService: locator<NotesService>());
    _notesFuture = _controller.fetchMemories(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
      ),
      body: FutureBuilder<NotesResult>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _notes = snapshot.data!.notes;
            return NoteList(
              notes: _notes,
              showDate: false,
              onTap: (noteId) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteDetail(noteId: noteId),
                  ),
                );
              },
              onDoubleTap: (noteId) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NoteDetail(noteId: noteId, enterEditing: true),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No notes found on this day.'));
          }
        },
      ),
    );
  }
}
