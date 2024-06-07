import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:happy_notes/screens/navigation/rail_navigation.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import 'home_page.dart';
import 'navigation/bottom_navigation.dart';
import 'new_note.dart';

// Constants
const kAppBarTitle = 'Happy Notes';
const kDrawerHeader = 'Happy Notes';
const kDrawerHeaderStyle = TextStyle(
  color: Colors.white,
  fontSize: 24,
);
const kSelectedItemColor = Colors.deepPurple;
const kUnselectedItemColor = Colors.grey;

class MainMenu extends StatefulWidget {
  final int initialPageIndex;
  const MainMenu({super.key, this.initialPageIndex = 0});

  @override
  MainMenuState createState() => MainMenuState();
}

class MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();
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
        HomePage(key: homePageKey,),
        NewNote(
          isPrivate: false,
          onNoteSaved: () async {
            setState(() {
              _selectedIndex = 0;
            });
            await homePageKey.currentState?.refreshPage();
          },
        ),
      ],
    );
  }

  void switchToPage(int index) {
    // Use a post-frame callback to defer the state change
      setState(() {
        _selectedIndex = index;
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppBarTitle),
      ),
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
          : BottomNavigation(currentIndex: _selectedIndex, onTap: switchToPage,),
    );
  }
}
