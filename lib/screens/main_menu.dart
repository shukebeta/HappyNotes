import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:happy_notes/screens/navigation/rail_navigation.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import 'home_page.dart';
import 'navigation/bottom_navigation.dart';
import 'new_note.dart';
import 'note_detail.dart';

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
  final GlobalKey<NewNoteState> newNoteKey = GlobalKey<NewNoteState>();
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
          key: newNoteKey,
          isPrivate: false,
          onNoteSaved: (int? noteId) async {
            setState(() {
              _selectedIndex = 0;
            });
            if (noteId != null) {
              if (homePageKey.currentState?.isFirstPage ?? false) {
                await homePageKey.currentState?.refreshPage();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Successfully saved. Click here to view.'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoteDetail(
                                  noteId: noteId),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  void switchToPage(int index) {
      if (_selectedIndex == 1 && index != 1) {
        newNoteKey.currentState?.setFocus(false);
      }
      setState(() {
        _selectedIndex = index;
      });
      if (index == 1) {
        newNoteKey.currentState?.setFocus(true);
      }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width >= 600;

    return Scaffold(
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
          : BottomNavigation(currentIndex: _selectedIndex, onTap: switchToPage,),
    );
  }
}
