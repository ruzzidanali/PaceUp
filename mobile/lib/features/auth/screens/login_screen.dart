import 'package:flutter/material.dart';
import 'package:mobile/core/navigation/app_shell.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/auth_state.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({super.key, required this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthController _authController;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Username/email and password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.login(email: identifier, password: password);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AppShell(authController: _authController),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkBackground
        : PaceUpColors.lightBackground;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final secondaryPanelColor = isDark
        ? PaceUpColors.darkPanelSecondary
        : PaceUpColors.lightPanelSecondary;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    final textColor = isDark ? PaceUpColors.darkText : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 60,
                  maxWidth: 460,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrandMark(),
                    const SizedBox(height: 30),
                    Text(
                      'WELCOME BACK',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.sectionTitle(
                        PaceUpColors.electricGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PACEUP',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.heroMetric(textColor)
                          .copyWith(fontSize: 56, height: 0.95),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep moving. Keep building your pace.',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.body(mutedColor),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: panelColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel('USERNAME OR EMAIL', mutedColor),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _identifierController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: PaceUpTypography.body(textColor),
                            cursorColor: PaceUpColors.electricGreen,
                            decoration: _inputDecoration(
                              hintText: 'Username or email',
                              icon: Icons.alternate_email_rounded,
                              secondaryPanelColor: secondaryPanelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildFieldLabel('PASSWORD', mutedColor),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            style: PaceUpTypography.body(textColor),
                            cursorColor: PaceUpColors.electricGreen,
                            decoration: _inputDecoration(
                              hintText: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              secondaryPanelColor: secondaryPanelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: mutedColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _login,
                              style: FilledButton.styleFrom(
                                backgroundColor: PaceUpColors.electricGreen,
                                foregroundColor: PaceUpColors.greenInk,
                                disabledBackgroundColor: PaceUpColors
                                    .electricGreen
                                    .withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _isLoading
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: PaceUpColors.greenInk,
                                        ),
                                      )
                                    : Text(
                                        'SIGN IN',
                                        key: const ValueKey('sign-in'),
                                        style: PaceUpTypography.label(
                                          PaceUpColors.greenInk,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen(
                                      authController: _authController,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: PaceUpColors.electricGreen,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: PaceUpTypography.bodyMedium(
                                  PaceUpColors.electricGreen,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NEW TO PACEUP?',
                          style: PaceUpTypography.label(mutedColor),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RegisterScreen(
                                        authController: _authController,
                                      ),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: PaceUpColors.electricGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'CREATE ACCOUNT',
                            style: PaceUpTypography.label(
                              PaceUpColors.electricGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'MOVE WITH PURPOSE.',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.sectionTitle(
                        mutedColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandMark() {
    return Center(
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: PaceUpColors.electricGreen,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: PaceUpColors.electricGreen.withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_run_rounded,
          color: PaceUpColors.greenInk,
          size: 34,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Text(label, style: PaceUpTypography.label(color));
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    required Color secondaryPanelColor,
    required Color borderColor,
    required Color mutedColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: PaceUpTypography.body(mutedColor),
      prefixIcon: Icon(icon, color: mutedColor, size: 19),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: secondaryPanelColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: PaceUpColors.electricGreen,
          width: 1.3,
        ),
      ),
    );
  }
}
