import 'package:flutter/material.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/util.dart';
import '../components/floating_pagination.dart';
import '../../dependency_injection.dart';
import '../components/note_list.dart';
import '../components/pagination_controls.dart';
import '../../entities/note.dart';
import '../account/user_session.dart';
import 'discovery_controller.dart';
import '../new_note/new_note.dart';
import '../../app_config.dart';
import '../components/controllers/tag_cloud_controller.dart';
import '../components/tappable_app_bar_title.dart';

class Discovery extends StatefulWidget {
  const Discovery({super.key});

  @override
  DiscoveryState createState() => DiscoveryState();
}

class DiscoveryState extends State<Discovery> {
  late DiscoveryController _discoveryController;
  late TagCloudController _tagCloudController;
  int currentPageNumber = 1;
  bool showPageSelector = false;

  bool get isFirstPage => currentPageNumber == 1;

  bool get isLastPage => currentPageNumber == _discoveryController.totalPages;

  @override
  void initState() {
    super.initState();
    _discoveryController = locator<DiscoveryController>();
    _tagCloudController = locator<TagCloudController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    navigateToPage(currentPageNumber);
  }

  Future<bool> navigateToPage(int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= _discoveryController.totalPages) {
      await _discoveryController.loadNotes(context, pageNumber);
      setState(() {
        currentPageNumber = pageNumber;
        showPageSelector = false;
      });
      return true;
    }
    return false;
  }

  Future<bool> refreshPage() async {
    return await navigateToPage(currentPageNumber);
  }

  @override
  Widget build(BuildContext context) {
    UserSession().isDesktop = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(
          title: TappableAppBarTitle(
            title: 'Shared Notes',
            onTap: () => NavigationHelper.showTagInputDialog(context),
            onLongPress: () async {
              var tagData = await _tagCloudController.loadTagCloud(context);
              if (!mounted) return;
              NavigationHelper.showTagDiagram(context, tagData);
            },
          ),
          actions: [
            _buildNewNoteButton(context),
          ]),
      body: Stack(
        children: [
          _buildBody(),
          if (_discoveryController.totalPages > 1 && !UserSession().isDesktop)
            FloatingPagination(
              currentPage: currentPageNumber,
              totalPages: _discoveryController.totalPages,
              navigateToPage: navigateToPage,
            ),
        ],
      ),
    );
  }

  IconButton _buildNewNoteButton(BuildContext context) {
    return IconButton(
      icon: Util.writeNoteIcon(),
      tooltip: AppConfig.privateNoteOnlyIsEnabled
          ? 'New Private Note'
          : 'New Public Note',
      onPressed: () async {
        final scaffoldContext = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => NewNote(
              isPrivate: false,
              onNoteSaved: (Note note) async {
                navigator.pop();
                if (isFirstPage && !note.isPrivate) {
                  await refreshPage();
                  return;
                }
                scaffoldContext.showSnackBar(
                  SnackBar(
                    content:
                        const Text('Successfully saved. Click here to view.'),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'View',
                      onPressed: () async {
                        await navigator.push(
                          MaterialPageRoute(
                            builder: (context) => NoteDetail(note: note),
                          ),
                        );
                      },
                    ),
                  ),
                );
                return;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_discoveryController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_discoveryController.notes.isEmpty) {
      return const Center(child: Text('Create a new note to get started.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NoteList(
            showAuthor: true,
            notes: _discoveryController.notes,
            onTap: (note) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(note: note),
                ),
              );
              await navigateToPage(currentPageNumber);
            },
            onDoubleTap: (note) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(
                      note: note,
                      enterEditing: note.userId == UserSession().id),
                ),
              );
              navigateToPage(currentPageNumber);
            },
            onTagTap: (note, tag) =>
                NavigationHelper.onTagTap(context, note, tag),
            onRefresh: () async => await refreshPage(),
            onDelete: (note) async {
              if (note.userId == UserSession().id) {
                await _discoveryController.deleteNote(context, note.id);
              }
            },
          ),
        ),
        if (_discoveryController.totalPages > 1 && UserSession().isDesktop)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _discoveryController.totalPages,
            navigateToPage: navigateToPage,
          ),
      ],
    );
  }
}
