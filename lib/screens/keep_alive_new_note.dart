import 'package:flutter/cupertino.dart';
import 'package:happy_notes/components/LifecycleAwarePage.dart';

import 'new_note.dart';

class KeepAliveNewNote extends LifecycleAwarePage {
  const KeepAliveNewNote({super.key, required this.isPrivate});

  final bool isPrivate;

  @override
  KeepAliveNewNoteState createState() => KeepAliveNewNoteState();

  @override
  void onPageBecomesActive() {
    // TODO: implement onPageBecomesActive
  }

  @override
  void onPageBecomesInactive() {
    // TODO: implement onPageBecomesInactive
  }
}

class KeepAliveNewNoteState extends State<KeepAliveNewNote> {
  final NewNote _newNote = const NewNote(isPrivate: false);

  @override
  Widget build(BuildContext context) {
    return _newNote;
  }
}