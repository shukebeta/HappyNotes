# Happy Notes - Development Guidelines

## Build & Test Commands
- Run app: `flutter run`
- Install dependencies: `flutter pub get`
- Build for Android: `flutter build apk`
- Build for iOS: `flutter build ios`
- Run all tests: `flutter test`
- Run single test: `flutter test test/path_to_test.dart`
- Run specific test group: `flutter test test/path_to_test.dart --name="Group name"`
- Analyze code: `flutter analyze`

## Code Style Guidelines
- **Naming**: Classes=PascalCase, variables/methods=camelCase, files=snake_case, private members=_prefixed
- **Imports**: Flutter packages first, project imports next, relative imports last
- **Error Handling**: Use try-catch for API calls, custom exceptions (ApiException), and Util.showError()
- **Architecture**: Follow MVC pattern - controllers separate from UI components
- **State Management**: Provider pattern with dependency injection via get_it
- **Types**: Always specify types for parameters, return values, and variables
- **Documentation**: Document all non-trivial methods and parameters
- **Formatting**: Use standard Dart formatter with flutter_lints package rules
- **Testing**: Group related tests, use descriptive test names, mock external dependencies