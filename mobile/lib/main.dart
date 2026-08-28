import 'package:flutter/material.dart';

import 'core/navigation/app_shell.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_state.dart';

void main() {
  runApp(const PaceUpApp());
}

class PaceUpApp extends StatefulWidget {
  const PaceUpApp({super.key});

  @override
  State<PaceUpApp> createState() => _PaceUpAppState();
}

class _PaceUpAppState extends State<PaceUpApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _authController.restoreSession();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaceUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    switch (_authController.state.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthStatus.authenticated:
        return AppShell(authController: _authController);

      case AuthStatus.unauthenticated:
        return LoginScreen(authController: _authController);
    }
  }
}
