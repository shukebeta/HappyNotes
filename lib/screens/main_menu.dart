import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_notes/screens/discovery/discovery.dart';
import 'package:happy_notes/screens/navigation/rail_navigation.dart';
import 'package:happy_notes/screens/settings/settings.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import '../app_config.dart';
import '../services/dialog_services.dart';
import 'home_page/home_page.dart';
import 'memories/memories.dart';
import 'navigation/bottom_navigation.dart';
import 'new_note/new_note.dart';

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
          onSaveSuccessInMainMenu: _handleSaveSuccessFromNewNoteTab, // Pass the handler
        ),
        if (kIsWeb) const Discovery(),
        Settings(
          key: settingsKey,
          onLogout: null, // No longer needed - AuthProvider handles logout automatically
        ),
      ],
    );
  }


  // This method is called by NewNote when save is successful in the MainMenu context
  void _handleSaveSuccessFromNewNoteTab() {
    // Switch to the HomePage and trigger its refresh logic via switchToPage
    switchToPage(indexNotes);
  }

  // void _onNoteSaved(Note note) async { ... } // Delete this old method

  void switchToPage(int index) {
    final focusNode = FocusScope.of(context);
    if (_selectedIndex == indexNewNote && index != indexNewNote) {
      // Remove focus when switching away from NewNote page
      focusNode.unfocus();
    }
    switch (index) {
      case indexNewNote:
        if (!AppConfig.isIOSWeb) {
          Future.delayed(const Duration(milliseconds: 150),
              () => focusNode.requestFocus());
        }
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
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          if (true ==
              await DialogService.showConfirmDialog(context,
                  title: 'Yes to quit Happy Notes')) {
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
            if (isDesktop)
              RailNavigation(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: switchToPage),
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
