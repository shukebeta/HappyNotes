import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_config.dart';
import '../../utils/util.dart';
import '../account/user_session.dart';
import '../components/memory_list.dart';
import '../new_note/new_note.dart';
import '../../utils/navigation_helper.dart';
import '../../providers/memories_provider.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

class Memories extends StatefulWidget {
  const Memories({super.key});

  @override
  MemoriesState createState() => MemoriesState();
}

class MemoriesState extends State<Memories> with RouteAware {
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
    // Load memories when the screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final memoriesProvider = context.read<MemoriesProvider>();
      if (memoriesProvider.memories.isEmpty) {
        memoriesProvider.loadMemories();
      }
    });
  }

  @override
  void dispose() {
    UserSession.routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Refresh the memories page
  void refreshPage() {
    final memoriesProvider = context.read<MemoriesProvider>();
    memoriesProvider.refreshMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TappableAppBarTitle(
          title: 'My Memories',
          onTap: () => NavigationHelper.showTagInputDialog(context),
          onLongPress: () async {
            final navigator = Navigator.of(context);
            final tagCloudController = TagCloudController();
            final tagData = await tagCloudController.loadTagCloud(context);
            if (!mounted) return;
            NavigationHelper.showTagDiagram(navigator.context, tagData);
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
      tooltip: AppConfig.privateNoteOnlyIsEnabled ? 'New Private Note' : 'New Public Note',
      onPressed: () async {
        final navigator = Navigator.of(context);
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: AppConfig.privateNoteOnlyIsEnabled,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<MemoriesProvider>(
      builder: (context, memoriesProvider, child) {
        if (memoriesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (memoriesProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${memoriesProvider.error}'),
                ElevatedButton(
                  onPressed: () => memoriesProvider.refreshMemories(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (memoriesProvider.memories.isEmpty) {
          return const Center(
            child: Text('No memories available. Compose notes from now on'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: MemoryList(
                notes: memoriesProvider.memories,
                onRefresh: () async => await memoriesProvider.refreshMemories(),
              ),
            ),
          ],
        );
      },
    );
  }
}
