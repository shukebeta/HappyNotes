import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/apis/file_uploader_api.dart';
import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/entities/mastodon_user_account.dart';
import 'package:happy_notes/screens/discovery/discovery_controller.dart';
import 'package:happy_notes/screens/home_page/home_page_controller.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import 'package:happy_notes/screens/settings/mastodon_sync_settings_controller.dart';
import 'package:happy_notes/screens/settings/telegram_sync_settings_controller.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';
import 'package:happy_notes/screens/tag_notes/tag_notes_controller.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/image_service.dart';
import 'package:happy_notes/services/mastodon_user_account_service.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/services/telegram_settings_service.dart';
import 'package:happy_notes/services/user_settings_service.dart';
import 'package:happy_notes/utils/token_utils.dart';

import 'apis/mastodon_user_account_api.dart';
import 'apis/note_tag_api.dart';
import 'apis/telegram_settings_api.dart';

final locator = GetIt.instance;

void init() {
  _registerApis();
  _registerServices();
  _registerControllers();
  _registerUtils();
}

void _registerApis() {
  locator.registerLazySingleton(() => NoteTagApi());
  locator.registerLazySingleton(() => FileUploaderApi());
  locator.registerLazySingleton(() => AccountApi());
  locator.registerLazySingleton(() => UserSettingsApi());
  locator.registerLazySingleton(() => TelegramSettingsApi());
  locator.registerLazySingleton(() => MastodonUserAccountApi());
}

void _registerServices() {
  locator.registerLazySingleton(() => NoteTagService(noteTagApi: locator()));
  locator.registerLazySingleton(() => NotesService());
  locator.registerLazySingleton(() => ImageService());
  locator.registerLazySingleton(() => AccountService(
    accountApi: locator(),
    userSettingsService: locator(),
    tokenUtils: locator(),
  ));
  locator.registerLazySingleton(() => UserSettingsService(userSettingsApi: locator()));
  locator.registerLazySingleton(() => TelegramSettingsService(telegramSettingsApi: locator()));
  locator.registerLazySingleton(() => MastodonUserAccountService(mastodonUserAccountApi: locator()));
}

void _registerControllers() {
  locator.registerFactory(() => SettingsController(
    accountService: locator(),
    userSettingsService: locator(),
  ));
  locator.registerLazySingleton(() => TelegramSyncSettingsController(telegramSettingService: locator()));
  locator.registerLazySingleton(() => MastodonSyncSettingsController(mastodonUserAccountService: locator()));
  locator.registerFactory(() => NewNoteController(notesService: locator()));
  locator.registerFactory(() => HomePageController(
    notesService: locator(),
    noteTagService: locator(),
  ));
  locator.registerFactory(() => TagNotesController(
    notesService: locator(),
    noteTagService: locator(),
  ));
  locator.registerFactory(() => DiscoveryController(notesService: locator()));
}

void _registerUtils() {
  locator.registerLazySingleton(() => TokenUtils());
}