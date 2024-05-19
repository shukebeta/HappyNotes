import 'package:happy_notes/screens/new_note_controller.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void init() {
  locator.registerLazySingleton<NotesService>(() => NotesService());
  locator.registerFactory<NewNoteController>(() => NewNoteController(notesService: locator()));

}
