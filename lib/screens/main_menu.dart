import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/screens/navigation/drawer_navigation.dart';
import 'package:happy_notes/screens/navigation/rail_navigation.dart';
import 'package:happy_notes/screens/registration.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import '../components/LifecycleAwarePage.dart';
import 'home_page.dart';
import 'login.dart';
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
  const MainMenu({super.key});

  @override
  MainMenuState createState() => MainMenuState();
}

class MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  LifecycleAwarePage? _currentPage;

  LazyLoadIndexedStack _getPage(int index) {
    return LazyLoadIndexedStack(
      index: index,
      preloadIndexes: const [0],
      children: const [
        HomePage(),
        NewNote(isPrivate: false),
      ],
    );
  }

  void _onItemTapped(int index) {
    // Use a post-frame callback to defer the state change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPage != null) {
        _currentPage!.onPageBecomesInactive();
      }
      _currentPage = _getPage(index).children[index] as LifecycleAwarePage;

      setState(() {
        _selectedIndex = index;
      });
      _currentPage!.onPageBecomesActive();
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
          if (isDesktop) RailNavigation(selectedIndex: _selectedIndex, onDestinationSelected: _onItemTapped),
          Expanded(
            child: _getPage(_selectedIndex)
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigation(currentIndex: _selectedIndex, onTap: _onItemTapped,),
    );
  }
}