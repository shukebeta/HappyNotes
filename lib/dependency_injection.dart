import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/apis/file_uploader_api.dart';
import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import 'package:happy_notes/screens/settings/mastodon_sync_settings_controller.dart';
import 'package:happy_notes/screens/settings/telegram_sync_settings_controller.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';
import 'package:happy_notes/screens/components/controllers/tag_cloud_controller.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/image_service.dart';
import 'package:happy_notes/services/mastodon_application_service.dart';
import 'package:happy_notes/services/mastodon_service.dart';
import 'package:happy_notes/services/mastodon_user_account_service.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/services/note_update_coordinator.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/services/telegram_settings_service.dart';
import 'package:happy_notes/services/user_settings_service.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:happy_notes/utils/app_logger_interface.dart';
import 'package:happy_notes/utils/app_logger.dart';

import 'apis/mastodon_application_api.dart';
import 'apis/mastodon_user_account_api.dart';
import 'apis/note_tag_api.dart';
import 'apis/telegram_settings_api.dart';
import 'providers/app_state_provider.dart';

final locator = GetIt.instance;

void init() {
  _registerUtils();
  _registerApis();
  _registerServices();
  _registerProviders();
  _registerControllers();
}

void _registerApis() {
  locator.registerLazySingleton(() => NoteTagApi());
  locator.registerLazySingleton(() => FileUploaderApi());
  locator.registerLazySingleton(() => AccountApi());
  locator.registerLazySingleton(() => UserSettingsApi());
  locator.registerLazySingleton(() => TelegramSettingsApi());
  locator.registerLazySingleton(() => MastodonApplicationApi());
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
        logger: locator(),
      ));
  locator.registerLazySingleton(
      () => UserSettingsService(userSettingsApi: locator()));
  locator.registerLazySingleton(
      () => TelegramSettingsService(telegramSettingsApi: locator()));
  locator.registerLazySingleton(
      () => MastodonApplicationService(mastodonApplicationApi: locator()));
  locator.registerLazySingleton(
      () => MastodonUserAccountService(mastodonUserAccountApi: locator()));
  locator.registerLazySingleton(() => MastodonService(
      mastodonApplicationService: locator(),
      mastodonUserAccountService: locator()));
  
  // Note: NoteUpdateCoordinator will be registered later in main.dart
  // after AppStateProvider is created, due to circular dependency
}

void _registerControllers() {
  locator.registerFactory(() => SettingsController(
        accountService: locator(),
        userSettingsService: locator(),
      ));
  locator.registerLazySingleton(
      () => TelegramSyncSettingsController(telegramSettingService: locator()));
  locator.registerLazySingleton(() =>
      MastodonSyncSettingsController(mastodonUserAccountService: locator()));
  locator.registerFactory(() => NewNoteController());
  locator.registerFactory(() => TagCloudController());
}

void _registerProviders() {
  // Register providers for dependency injection when needed
  // Note: Providers will be created via MultiProvider in main.dart
}

void _registerUtils() {
  locator.registerLazySingleton<AppLoggerInterface>(() => AppLogger());
  locator.registerLazySingleton(() => TokenUtils());
}
