import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:happy_notes/screens/new_note_controller.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/utils/token_utils.dart';

final locator = GetIt.instance;

void init() {
  locator.registerLazySingleton<NotesService>(() => NotesService());
  locator.registerLazySingleton<AccountService>(() => AccountService());
  locator.registerFactory<NewNoteController>(() => NewNoteController(notesService: locator()));
  locator.registerLazySingleton<TokenUtils>(() => TokenUtils());
  locator.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

}
