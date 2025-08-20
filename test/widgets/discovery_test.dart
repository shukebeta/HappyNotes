import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/discovery/discovery.dart';
import '../test_helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    registerTestMocks();
  });

  testWidgets('Discovery screen renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildWidgetTestHarness(const Discovery()),
    );

    // Wait for initial async operations to complete
    await tester.pumpAndSettle();

    expect(find.byType(Discovery), findsOneWidget);
  });
}
