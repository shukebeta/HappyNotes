import 'package:flutter/material.dart';

// Constants
const kDrawerHeader = 'Happy Notes';
const kDrawerHeaderStyle = TextStyle(
  color: Colors.white,
  fontSize: 24,
);
const kSelectedItemColor = Colors.deepPurple;

class DrawerNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const DrawerNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children:  [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: kSelectedItemColor,
            ),
            child: Text(
              kDrawerHeader,
              style: kDrawerHeaderStyle,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.collections_outlined),
            title: const Text('Notes'),
            onTap: () => onItemTapped(0),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Memory'),
            onTap: () => onItemTapped(1),
          ),
          ListTile(
            leading: const Icon(Icons.note_add_outlined),
            title: const Text('New Note'),
            onTap: onItemTapped(2),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Discovery'),
            onTap: onItemTapped(3),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: onItemTapped(4),
          ),
        ],
      ),
    );
  }
}
