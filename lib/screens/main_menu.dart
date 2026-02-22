import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_notes/screens/navigation/rail_navigation.dart';
import 'package:happy_notes/screens/settings/settings.dart';
import 'package:happy_notes/screens/tags/my_tags_page.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import '../services/dialog_services.dart';
import 'home_page/home_page.dart';
import 'memories/memories.dart';
import 'navigation/bottom_navigation.dart';
import 'search/search_tab.dart';

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
        const SearchTab(),
        const MyTagsPage(),
        Settings(
          key: settingsKey,
          onLogout: null,
        ),
      ],
    );
  }

  void switchToPage(int index) {
    switch (index) {
      case indexNotes:
        break;
      case indexMemories:
        break;
      case indexTags:
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
          if (true == await DialogService.showConfirmDialog(context, title: 'Yes to quit Happy Notes')) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
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
