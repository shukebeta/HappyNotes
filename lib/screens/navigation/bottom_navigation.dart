import 'package:flutter/material.dart';

// Constants
const kSelectedItemColor = Colors.deepPurple;
const kUnselectedItemColor = Colors.grey;

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
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.note_add_outlined),
        //   label: 'New Note',
        // ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.public),
        //   label: 'Discovery',
        // ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.settings),
        //   label: 'Settings',
        // ),
      ],
    );
  }
}