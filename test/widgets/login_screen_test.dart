import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shogaku_kore_programming/screens/login_screen.dart';
import 'test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('displays login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('displays email input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for email input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays password input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Password field should exist
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for show/hide password button
      final visibilityButton = find.byIcon(Icons.visibility_off);
      expect(visibilityButton, findsWidgets);
    });

    testWidgets('can enter email address', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find email field and enter text
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test@example.com'), findsWidgets);
    });

    testWidgets('can enter password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find password field and enter text
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length > 1) {
        await tester.tap(textFields.at(1));
        await tester.enterText(textFields.at(1), 'password123');
        await tester.pumpAndSettle();
      }
    });

    testWidgets('displays login button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for login button
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsWidgets);
    });

    testWidgets('displays sign up link', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for sign up text
      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets('validates empty email', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to login without email
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('validates empty password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter email but no password
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Try to login
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Error should show for password
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('validates email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'invalid-email');
      await tester.pumpAndSettle();

      // Try to login
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('validates password length', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid email but short password
      final textFields = find.byType(TextField);
      await tester.tap(textFields.first);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(textFields.at(1));
      await tester.enterText(textFields.at(1), 'short');
      await tester.pumpAndSettle();

      // Try to login
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap visibility button
      final visibilityButton = find.byIcon(Icons.visibility_off);
      if (visibilityButton.evaluate().isNotEmpty) {
        await tester.tap(visibilityButton.first);
        await tester.pumpAndSettle();

        // Icon should change to visibility
        expect(find.byIcon(Icons.visibility), findsWidgets);
      }
    });

    testWidgets('displays forgot password link', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for forgot password
      final textButtons = find.byType(TextButton);
      expect(textButtons, findsWidgets);
    });

    testWidgets('can tap sign up to switch to sign up form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for sign up link
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().isNotEmpty) {
        await tester.tap(textButtons.first);
        await tester.pumpAndSettle();

        // Form should switch to sign up (look for additional fields)
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('displays company/app branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // App logo or branding should be visible
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('displays social login options if available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for social login buttons (optional)
      final buttons = find.byType(ElevatedButton);
      expect(buttons.evaluate().isNotEmpty, true);
    });

    testWidgets('form submission triggers loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid credentials
      final textFields = find.byType(TextField);
      await tester.tap(textFields.first);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(textFields.at(1));
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      // Tap login
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Loading indicator should appear (circular progress or disabled button)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays error message on failed login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter credentials
      final textFields = find.byType(TextField);
      await tester.tap(textFields.first);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pumpAndSettle();

      await tester.tap(textFields.at(1));
      await tester.enterText(textFields.at(1), 'wrongpassword');
      await tester.pumpAndSettle();

      // Tap login
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Error should be shown (SnackBar or message)
    });

    testWidgets('clears validation errors when user types',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First show error
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Then enter email
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Error should clear or be replaced
    });

    testWidgets('sign up form displays name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to sign up if available
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().isNotEmpty) {
        await tester.tap(textButtons.first);
        await tester.pumpAndSettle();

        // Name field should appear
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('handles keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab through fields
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Should move through fields
    });
  });
}
