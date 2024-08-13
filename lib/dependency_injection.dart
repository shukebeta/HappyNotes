import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/screens/discovery/discovery_controller.dart';
import 'package:happy_notes/screens/home_page/home_page_controller.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import 'package:happy_notes/screens/settings/note_sync_settings_controller.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';
import 'package:happy_notes/screens/tag_notes/tag_notes_controller.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/services/telegram_settings_service.dart';
import 'package:happy_notes/services/user_settings_service.dart';
import 'package:happy_notes/utils/token_utils.dart';

import 'apis/note_tag_api.dart';
import 'apis/telegram_settings_api.dart';

final locator = GetIt.instance;

void init() {
  locator.registerLazySingleton<NoteTagApi>(() => NoteTagApi());
  locator.registerLazySingleton<NoteTagService>(() => NoteTagService(noteTagApi: locator()));

  locator.registerLazySingleton<NotesService>(() => NotesService());
  locator.registerLazySingleton<AccountApi>(() => AccountApi());
  locator.registerLazySingleton<AccountService>(() => AccountService(accountApi: locator(), userSettingsService: locator(), tokenUtils: locator()));

  locator.registerLazySingleton<UserSettingsApi>(() => UserSettingsApi());
  locator.registerLazySingleton<UserSettingsService>(() => UserSettingsService(userSettingsApi: locator()));
  locator.registerFactory<SettingsController>(() => SettingsController(accountService: locator(), userSettingsService: locator()));

  locator.registerLazySingleton<TelegramSettingsApi>(() => TelegramSettingsApi());
  locator.registerLazySingleton<TelegramSettingsService>(() => TelegramSettingsService(telegramSettingsApi: locator()));
  locator.registerLazySingleton<NoteSyncSettingsController>(() => NoteSyncSettingsController(telegramSettingService: locator()));

  locator.registerFactory<NewNoteController>(() => NewNoteController(notesService: locator()));
  locator.registerFactory<HomePageController>(() => HomePageController(notesService: locator()));
  locator.registerFactory<TagNotesController>(() => TagNotesController(notesService: locator(), noteTagService: locator()));
  locator.registerFactory<DiscoveryController>(() => DiscoveryController(notesService: locator()));

  locator.registerLazySingleton<TokenUtils>(() => TokenUtils());
}
