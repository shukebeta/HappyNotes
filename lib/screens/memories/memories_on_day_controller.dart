import 'package:flutter/material.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:intl/intl.dart';
import '../../services/notes_services.dart';

class MemoriesOnDayController {
  final NotesService _notesService;

  MemoriesOnDayController({required NotesService notesService})
      : _notesService = notesService;

  Future<NotesResult> fetchMemories(DateTime date) async {
    var notesResult = await _notesService.memoriesOn(DateFormat('yyyyMMdd').format(date));
    return notesResult;
  }

  Future<void> deleteNote(BuildContext context, int noteId, Function(bool needRefresh) onSuccess) async {
    try {
      await _notesService.delete(noteId);
      onSuccess(true);
    } catch (error) {
      onSuccess(false);
    }
  }
}
