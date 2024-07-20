import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_notes/screens/discovery/discovery.dart';
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/screens/navigation/rail_navigation.dart';
import 'package:happy_notes/screens/settings/settings.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import '../entities/note.dart';
import '../services/dialog_services.dart';
import 'home_page/home_page.dart';
import 'memories/memories.dart';
import 'navigation/bottom_navigation.dart';
import 'new_note/new_note.dart';
import 'note_detail/note_detail.dart';

// Constants
const kAppBarTitle = 'Happy Notes';

class MainMenu extends StatefulWidget {
  final int initialPageIndex;

  const MainMenu({super.key, this.initialPageIndex = 0});

  @override
  MainMenuState createState() => MainMenuState();
}

class MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<MemoriesState> memoriesKey = GlobalKey<MemoriesState>();
  final GlobalKey<NewNoteState> newNoteKey = GlobalKey<NewNoteState>();
  final GlobalKey<SettingsState> settingsKey = GlobalKey<SettingsState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
  }

  LazyLoadIndexedStack _getPage(int index) {
    return LazyLoadIndexedStack(
      index: index,
      preloadIndexes: const [0],
      children: [
        HomePage(
          key: homePageKey,
        ),
        Memories(key: memoriesKey),
        NewNote(
          key: newNoteKey,
          isPrivate: true,
          onNoteSaved: _onNoteSaved,
        ),
        const Discovery(),
        Settings(
          key: settingsKey,
          onLogout: _onLogout,
        ),
      ],
    );
  }

  void _onLogout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InitialPage()));
  }

  void _onNoteSaved(Note note) async {
    setState(() {
      _selectedIndex = indexNotes;
    });
    if (note.id > 0) {
      if (homePageKey.currentState?.isFirstPage ?? false) {
        await homePageKey.currentState?.refreshPage();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully saved. Click here to view.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetail(note: note),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void switchToPage(int index) {
    if (_selectedIndex == indexNewNote && index != indexNewNote) {
      // Unfocus when switching away from NewNote page
      FocusScope.of(context).unfocus();
    }
    switch (index) {
      case indexNewNote:
        Future.delayed(const Duration(milliseconds: 150), () => FocusScope.of(context).requestFocus());
        break;
      case indexNotes:
        homePageKey.currentState?.refreshPage();
        break;
      case indexMemories:
        memoriesKey.currentState?.refreshPage();
        break;
      case indexSharedNotes:
        memoriesKey.currentState?.setState(() {});
        break;
      case indexSettings:
        settingsKey.currentState?.setState(() {});
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          if (true == await DialogService.showConfirmDialog(context, title: 'Yes to quit Happy Notes')) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text(kAppBarTitle),
        // ),
        body: Row(
          children: [
            if (isDesktop) RailNavigation(selectedIndex: _selectedIndex, onDestinationSelected: switchToPage),
            Expanded(
              child: _getPage(_selectedIndex),
            ),
          ],
        ),
        bottomNavigationBar: isDesktop
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
                child: BottomNavigation(
                  currentIndex: _selectedIndex,
                  onTap: switchToPage,
                ),
              ),
      ),
    );
  }
}
