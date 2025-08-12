import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/trash_bin/trash_bin_page.dart';
import '../test_helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    registerTestMocks();
  });

  testWidgets('TrashBinPage renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildWidgetTestHarness(const TrashBinPage()),
    );

    // Wait for initial async operations to complete
    await tester.pumpAndSettle();

    expect(find.byType(TrashBinPage), findsOneWidget);
  });
}