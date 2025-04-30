import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../../utils/util.dart';
import '../account/user_session.dart';
import '../components/memory_list.dart';
import '../../dependency_injection.dart';
import '../../services/notes_services.dart';
import '../new_note/new_note.dart';
import '../../utils/navigation_helper.dart';
import 'memories_controller.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

class Memories extends StatefulWidget {
  const Memories({super.key});

  @override
  MemoriesState createState() => MemoriesState();
}

class MemoriesState extends State<Memories> with RouteAware {
  late MemoriesController _memoriesController;
  late TagCloudController _tagCloudController;

  @override
  void initState() {
    super.initState();
    _memoriesController = MemoriesController(locator<NotesService>());
    _tagCloudController = locator<TagCloudController>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      UserSession.routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
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
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TappableAppBarTitle(
          title: 'My Memories',
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            var tagData = await _tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(context, tagData);
          },
        ),
        actions: [_buildNewNoteButton(context)],
      ),
      body: _buildBody(),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: Util.writeNoteIcon(),
      tooltip: AppConfig.privateNoteOnlyIsEnabled
          ? 'New Private Note'
          : 'New Public Note',
      onPressed: () async {
        final navigator = Navigator.of(context);
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
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
      return const Center(
          child: Text('No memories available. Compose notes from now on'));
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
