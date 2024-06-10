import 'package:flutter/material.dart';

class RailNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const RailNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.collections_outlined),
          selectedIcon: Icon(Icons.collections_outlined, color: Colors.blue),
          label: Text('Notes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today),
          selectedIcon: Icon(Icons.calendar_today, color: Colors.blue),
          label: Text('Memories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.note_add_outlined),
          selectedIcon: Icon(Icons.note_add_outlined, color: Colors.blue),
          label: Text('New Note'),
        ),
        // NavigationRailDestination(
        //   icon: Icon(Icons.public),
        //   selectedIcon: Icon(Icons.public, color: Colors.blue),
        //   label: Text('Discovery'),
        // ),
        // NavigationRailDestination(
        //   icon: Icon(Icons.settings),
        //   selectedIcon: Icon(Icons.settings, color: Colors.blue),
        //   label: Text('Settings'),
        // ),
      ],
    );
  }
}
