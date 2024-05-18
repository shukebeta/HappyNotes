import 'package:HappyNotes/screens/new_note_controller.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';

class NewNote extends StatefulWidget {
  final bool isPrivate;

  const NewNote({super.key, required this.isPrivate});

  @override
  NewNoteState createState() => NewNoteState();
}

class NewNoteState extends State<NewNote> {
  final newNoteController = locator<NewNoteController>();
  late FocusNode _noteFocusNode;
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.isPrivate;
    _noteFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _noteFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => newNoteController.onPopHandler(context, didPop),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Note'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: TextField(
                    controller: newNoteController.noteController,
                    focusNode: _noteFocusNode,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Write your note here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Private Note'),
                      Switch(
                        value: _isPrivate,
                        onChanged: (bool value) {
                          setState(() {
                            _isPrivate = value;
                          });
                        },
                      ),
                    ],
                  ),
                  FloatingActionButton(
                    onPressed: () => newNoteController.saveNote(context, _isPrivate),
                    child: const Icon(Icons.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    super.dispose();
  }
}
