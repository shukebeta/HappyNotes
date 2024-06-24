import 'package:flutter/material.dart';
import '../components/memory_list.dart';
import '../../dependency_injection.dart';
import '../../services/notes_services.dart';
import '../new_note/new_note.dart';
import 'memories_controller.dart';

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
    refreshPage();
  }

  Future<void> refreshPage() async {
    await _memoriesController.loadNotes(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        actions: [_buildNewNoteButton(context)],
      ),
      body: _buildBody(),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () async {
        final scaffoldContext = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: false, // this entry is always for public note
              onNoteSaved: (note) async {
                navigator.pop();
                await refreshPage();
              },
            ),
          ),
        );
      },
    );
  }
 
  Widget _buildBody() {
    if (_memoriesController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memoriesController.notes.isEmpty) {
      return const Center(child: Text('No memories available. Compose notes from now on'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MemoryList(
            notes: _memoriesController.notes,
            onRefresh: () async => await refreshPage(),
          ),
        ),
      ],
    );
  }
}
