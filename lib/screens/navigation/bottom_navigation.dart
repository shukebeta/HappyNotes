import 'package:flutter/material.dart';

// Constants
const kSelectedItemColor = Colors.deepPurple;
const kUnselectedItemColor = Colors.grey;
const int indexNotes = 0;
const int indexMemories = 1;
const int indexNewNote = 2;
const int indexSharedNotes = 3;
const int indexMore = 4;

// Remember to adjust rail_navigation.dart as well
// when you adjust the order of the menu items
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: kSelectedItemColor,
      unselectedItemColor: kUnselectedItemColor,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.collections_outlined),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Memories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note_add_outlined),
          label: 'New Note',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.public),
          label: 'Discovery',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.settings),
        //   label: 'Settings',
        // ),
      ],
    );
  }
}