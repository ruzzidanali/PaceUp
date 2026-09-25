import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
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

  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  StreamSubscription<Uri>? _linkSubscription;

  String? _pendingResetToken;

  @override
  void initState() {
    super.initState();

    _authController = AuthController();

    _initDeepLinks();
    _restoreSession();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {
      // Ignore malformed or unavailable initial deep links.
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'paceup') {
      return;
    }

    if (uri.host != 'reset-password') {
      return;
    }

    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      return;
    }

    _pendingResetToken = token;

    final navigator = _navigatorKey.currentState;

    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            authController: _authController,
            token: token,
          ),
        ),
        (route) => false,
      );

      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _restoreSession() async {
    await _authController.restoreSession();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaceUp',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: PaceUpTheme.light(),
      darkTheme: PaceUpTheme.dark(),
      themeMode: ThemeMode.dark,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final resetToken = _pendingResetToken;

    if (resetToken != null && resetToken.isNotEmpty) {
      return ResetPasswordScreen(
        authController: _authController,
        token: resetToken,
      );
    }

    switch (_authController.state.status) {
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );

      case AuthStatus.authenticated:
        return AppShell(
          authController: _authController,
        );

      case AuthStatus.unauthenticated:
        return LoginScreen(
          authController: _authController,
        );
    }
  }
}