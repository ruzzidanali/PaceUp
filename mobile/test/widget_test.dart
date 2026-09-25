import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/services/auth_state.dart';

void main() {
  testWidgets('PaceUp login screen loads', (WidgetTester tester) async {
    final authController = AuthController();

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authController: authController)),
    );

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);

    authController.dispose();
  });
}
