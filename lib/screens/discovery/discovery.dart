import 'package:flutter/material.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import '../components/floating_pagination.dart';
import '../../dependency_injection.dart';
import '../components/note_list.dart';
import '../components/pagination_controls.dart';
import '../../entities/note.dart';
import '../account/user_session.dart';
import 'discovery_controller.dart';
import '../new_note/new_note.dart';

class Discovery extends StatefulWidget {
  const Discovery({super.key});

  @override
  DiscoveryState createState() => DiscoveryState();
}

class DiscoveryState extends State<Discovery> {
  late DiscoveryController _discoveryController;
  int currentPageNumber = 1;
  bool showPageSelector = false;

  bool get isFirstPage => currentPageNumber == 1;

  bool get isLastPage => currentPageNumber == _discoveryController.totalPages;

  @override
  void initState() {
    super.initState();
    _discoveryController = locator<DiscoveryController>();
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
    var isDesktop = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Notes'), actions: [
        _buildNewNoteButton(context),
      ]),
      body: Stack(
        children: [
          _buildBody(isDesktop),
          if (_discoveryController.totalPages > 1 && !isDesktop)
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
      icon: const Icon(Icons.edit),
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
                    content: const Text('Successfully saved. Click here to view.'),
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

  Widget _buildBody(bool isDesktop) {
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
                  builder: (context) => NoteDetail(note: note, enterEditing: note.userId == UserSession().id),
                ),
              );
              navigateToPage(currentPageNumber);
            },
            onRefresh: () async => await navigateToPage(currentPageNumber),
          ),
        ),
        if (_discoveryController.totalPages > 1 && isDesktop)
          PaginationControls(
            currentPage: currentPageNumber,
            totalPages: _discoveryController.totalPages,
            onPreviousPage: () => navigateToPage(currentPageNumber - 1),
            onNextPage: () => navigateToPage(currentPageNumber + 1),
          ),
      ],
    );
  }
}
