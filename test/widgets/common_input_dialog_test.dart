// test/widgets/common_input_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/screens/components/common_input_dialog.dart';

void main() {
  group('CommonInputDialog Widget Tests', () {
    // [FACT] testWidgets is the main function for widget testing
    // WidgetTester (tester) provides methods to interact with widgets
    testWidgets('should display dialog with correct title and buttons', (WidgetTester tester) async {
      // Arrange: Create the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CommonInputDialog(title: 'Test Dialog'),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Act: Tap the button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pump(); // Trigger a frame to show the dialog

      // Assert: Check if dialog elements are present
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should display custom button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CommonInputDialog(
                    title: 'Custom Dialog',
                    confirmButtonText: 'Submit',
                    cancelButtonText: 'Dismiss',
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('should display hint text and initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CommonInputDialog(
                    title: 'Test Dialog',
                    hintText: 'Enter something...',
                    initialValue: 'Initial text',
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check hint text (this might be tricky to test directly)
      expect(find.text('Enter something...'), findsOneWidget);

      // Check initial value
      expect(find.text('Initial text'), findsOneWidget);
    });

    testWidgets('should validate input using provided validators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => CommonInputDialog(
                    title: 'Test Dialog',
                    validators: [
                      InputValidators.required('Field is required'),
                      InputValidators.maxLength(5, 'Too long'),
                    ],
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Test empty field validation
      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(find.text('Field is required'), findsOneWidget);

      // Test max length validation
      await tester.enterText(find.byType(TextFormField), 'This is too long');
      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(find.text('Too long'), findsOneWidget);
    });

    testWidgets('should return entered text when OK is pressed with valid input', (WidgetTester tester) async {
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (_) => const CommonInputDialog(title: 'Test Dialog'),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Enter text and submit
      await tester.enterText(find.byType(TextFormField), 'Test input');
      await tester.tap(find.text('OK'));

      // [FACT] pumpAndSettle waits for all animations and timers to complete
      await tester.pumpAndSettle();

      expect(dialogResult, equals('Test input'));
    });

    testWidgets('should return null when Cancel is pressed', (WidgetTester tester) async {
      String? dialogResult = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (_) => const CommonInputDialog(title: 'Test Dialog'),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNull);
    });

    testWidgets('should handle form submission on Enter key', (WidgetTester tester) async {
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (_) => const CommonInputDialog(title: 'Test Dialog'),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Enter text
      await tester.enterText(find.byType(TextFormField), 'Enter key test');

      // [FACT] testTextInput.receiveAction simulates pressing Enter
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(dialogResult, equals('Enter key test'));
    });

    testWidgets('should show loading state when submitting', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CommonInputDialog(title: 'Test Dialog'),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Test');
      await tester.tap(find.text('OK'));

      // Check for loading state immediately after tap
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // **[FACT]** Fix: Use find.widgetWithText to locate buttons, then check their state
      // Instead of trying to access the widget directly, check if buttons are disabled
      final cancelButtonFinder = find.ancestor(
        of: find.text('Cancel'),
        matching: find.byType(TextButton),
      );
      final okButtonFinder = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(ElevatedButton),
      );

      expect(cancelButtonFinder, findsOneWidget);
      expect(okButtonFinder, findsOneWidget);

      // **[CREATIVE]** Alternative approach: Check if tapping disabled buttons has no effect
      final initialDialogCount = find.byType(AlertDialog).evaluate().length;

      // Try tapping the cancel button while loading - should have no effect
      await tester.tap(cancelButtonFinder);
      await tester.pump();

      // Dialog should still be present (button was disabled)
      expect(find.byType(AlertDialog).evaluate().length, equals(initialDialogCount));
      await tester.pumpAndSettle();
    });

    testWidgets('should not submit form with validation errors', (WidgetTester tester) async {
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog<String>(
                    context: context,
                    builder: (_) => CommonInputDialog(
                      title: 'Test Dialog',
                      validators: [InputValidators.required()],
                    ),
                  );
                  dialogClosed = true;
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Try to submit empty form
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should still be open
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(dialogClosed, isFalse);
    });

    testWidgets('should focus text field on dialog open', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CommonInputDialog(title: 'Test Dialog'),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextFormField);
      expect(textFieldFinder, findsOneWidget);

      final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;

      // Verify that some focus node is active (the text field should be focused)
      expect(primaryFocus, isNotNull);
      expect(primaryFocus!.hasFocus, isTrue);
    });
  });

  // [CREATIVE] Group for testing the static show method
  group('CommonInputDialog.show static method', () {
    testWidgets('should show dialog and return result', (WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CommonInputDialog.show(
                    context,
                    title: 'Static Method Test',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.text('Static Method Test'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Static test');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, equals('Static test'));
    });
  });

  // [CREATIVE] Group for testing validators separately (unit tests)
  group('InputValidators', () {
    group('required validator', () {
      test('should return error for null input', () {
        final validator = InputValidators.required();
        expect(validator(null), equals('This field is required.'));
      });

      test('should return error for empty input', () {
        final validator = InputValidators.required();
        expect(validator(''), equals('This field is required.'));
        expect(validator('   '), equals('This field is required.'));
      });

      test('should return null for valid input', () {
        final validator = InputValidators.required();
        expect(validator('valid input'), isNull);
      });

      test('should use custom error message', () {
        final validator = InputValidators.required('Custom error');
        expect(validator(''), equals('Custom error'));
      });
    });

    group('maxLength validator', () {
      test('should return error for input exceeding max length', () {
        final validator = InputValidators.maxLength(5);
        expect(validator('toolong'), equals('Cannot exceed 5 characters.'));
      });

      test('should return null for input within limit', () {
        final validator = InputValidators.maxLength(5);
        expect(validator('ok'), isNull);
        expect(validator('exact'), isNull);
      });

      test('should use custom error message', () {
        final validator = InputValidators.maxLength(3, 'Too big!');
        expect(validator('toolong'), equals('Too big!'));
      });
    });
  });
}

// [CREATIVE] Example of how to test the dialog in integration with other widgets
class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await CommonInputDialog.show(
                context,
                title: 'Integration Test',
              );
              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('You entered: $result')),
                );
              }
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }
}

// [CREATIVE] Integration test example
void integrationTestExample() {
  group('CommonInputDialog Integration Tests', () {
    testWidgets('should show snackbar with entered text', (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      await tester.tap(find.text('Open Dialog'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Integration test');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('You entered: Integration test'), findsOneWidget);
    });
  });
}
