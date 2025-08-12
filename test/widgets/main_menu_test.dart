import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/main_menu.dart';
import '../test_helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    // Ensure dotenv is loaded before any widget tests
    await dotenv.load(fileName: '.env');
    // Register mocks for all network APIs
    registerTestMocks();
  });

  testWidgets('MainMenu renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildWidgetTestHarness(const MainMenu()),
    );

    // Wait for initial async operations to complete
    await tester.pumpAndSettle();

    expect(find.byType(MainMenu), findsOneWidget);
  });
}