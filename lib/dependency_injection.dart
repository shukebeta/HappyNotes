import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/screens/discovery/discovery_controller.dart';
import 'package:happy_notes/screens/home_page/home_page_controller.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/utils/token_utils.dart';

final locator = GetIt.instance;

void init() {
  locator.registerLazySingleton<AccountApi>(() => AccountApi());
  locator.registerLazySingleton<NotesService>(() => NotesService());
  locator.registerLazySingleton<AccountService>(() => AccountService(accountApi: locator()));
  locator.registerFactory<NewNoteController>(() => NewNoteController(notesService: locator()));
  locator.registerFactory<HomePageController>(() => HomePageController(notesService: locator<NotesService>()));
  locator.registerFactory<DiscoveryController>(() => DiscoveryController(notesService: locator<NotesService>()));
  locator.registerFactory<SettingsController>(() => SettingsController(accountService: locator<AccountService>()));
  locator.registerLazySingleton<TokenUtils>(() => TokenUtils());
}
