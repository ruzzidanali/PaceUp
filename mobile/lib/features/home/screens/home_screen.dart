import 'package:flutter/material.dart';

import '../../auth/services/auth_state.dart';

class HomeScreen extends StatelessWidget {
  final AuthController authController;

  const HomeScreen({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    final user = authController.state.user;

    return Scaffold(
      body: Center(
        child: Text(
          'Welcome, ${user?.displayName ?? 'runner'}!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
