import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/components/tag_cloud.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import 'package:happy_notes/screens/components/shared_fab.dart';
import 'package:happy_notes/screens/new_note/new_note.dart';
import 'package:happy_notes/screens/tag_notes/tag_notes.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/utils/util.dart';

class MyTagsPage extends StatefulWidget {
  const MyTagsPage({super.key});

  @override
  State<MyTagsPage> createState() => MyTagsPageState();
}

class MyTagsPageState extends State<MyTagsPage> {
  late TagCloudController _tagCloudController;
  Map<String, int>? _tagData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tagCloudController = locator<TagCloudController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tagData == null) {
        _loadTags();
      }
    });
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _tagCloudController.loadTagCloud(context);
      if (mounted) {
        setState(() {
          _tagData = data;
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

  void _onTagTap(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagNotes(tag: tag, myNotesOnly: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTags,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(),
          Positioned(
            right: 16,
            bottom: 16,
            child: Opacity(
              opacity: 0.85,
              child: SharedFab(
                icon: Icons.edit_outlined,
                isPrivate: AppConfig.privateNoteOnlyIsEnabled,
                busy: false,
                mini: false,
                heroTag: 'fab_tags',
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final bool? savedSuccessfully = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewNote(isPrivate: AppConfig.privateNoteOnlyIsEnabled),
                    ),
                  );
                  if (savedSuccessfully ?? false) {
                    if (!mounted) return;
                    Util.showInfo(scaffoldMessenger, 'Note saved successfully.');
                  }
                },
              ),
            ),
          ),
        ],
      ),
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
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Unable to load tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTags,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tagData == null || _tagData!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tag, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No tags yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'Add #tags to your notes to organize them',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTags,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: TagCloud(
          tagData: _tagData!,
          onTagTap: _onTagTap,
        ),
      ),
    );
  }
}
