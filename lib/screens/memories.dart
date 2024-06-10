import 'package:flutter/material.dart';
import '../components/memory_list.dart';
import '../dependency_injection.dart';
import '../services/notes_services.dart';
import 'memories_controller.dart';
import 'note_detail.dart';

class Memories extends StatefulWidget {
  const Memories({super.key});

  @override
  MemoriesState createState() => MemoriesState();
}

class MemoriesState extends State<Memories> {
  late MemoriesController _memoriesController;

  @override
  void initState() {
    super.initState();
    _memoriesController = MemoriesController(locator<NotesService>());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    await _memoriesController.loadNotes(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_memoriesController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memoriesController.notes.isEmpty) {
      return const Center(
          child: Text(
              'No memories available. Compose notes from now on, and come back in a few days'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MemoryList(
            notes: _memoriesController.notes,
            onTap: (noteId) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(noteId: noteId),
                ),
              );
              await fetchMemories();
            },
            onDoubleTap: (noteId) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NoteDetail(noteId: noteId, enterEditing: true),
                ),
              );
              fetchMemories();
            },
            onRefresh: () async => await fetchMemories(),
          ),
        ),
      ],
    );
  }
}
