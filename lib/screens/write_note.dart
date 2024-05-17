import 'package:flutter/material.dart';

class WriteNote extends StatefulWidget {
  @override
  _WriteNoteState createState() => _WriteNoteState();
}

class _WriteNoteState extends State<WriteNote> {
  final TextEditingController _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final maxLines = MediaQuery.of(context).size.height ~/ 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Note'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _noteController,
                keyboardType: TextInputType.multiline,
                maxLines: maxLines,
                decoration: const InputDecoration(
                  hintText: 'Write your note here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic to save the note goes here
          String note = _noteController.text;
          // You can send the note to the backend, save it locally, etc.
          Navigator.pop(context); // Navigate back to the previous screen
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
