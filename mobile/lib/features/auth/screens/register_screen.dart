import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  final AuthController authController;

  const RegisterScreen({
    super.key,
    required this.authController,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final displayName = _displayNameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        displayName.isEmpty ||
        password.isEmpty) {
      _showError('All fields are required.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authController.register(
        username: username,
        email: email,
        displayName: displayName,
        password: password,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Account created successfully.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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

    final textColor = isDark
        ? PaceUpColors.darkText
        : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                18,
                24,
                32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                  maxWidth: 460,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 42,
                          minHeight: 42,
                        ),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: mutedColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBrandMark(),
                    const SizedBox(height: 28),
                    Text(
                      'CREATE ACCOUNT',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.sectionTitle(
                        PaceUpColors.electricGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'JOIN PACEUP',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.heroMetric(
                        textColor,
                      ).copyWith(
                        fontSize: 48,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Build your profile. Track your progress.\\n'
                      'Keep moving forward.',
                      textAlign: TextAlign.center,
                      style: PaceUpTypography.body(
                        mutedColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: panelColor,
                        border: Border.all(
                          color: borderColor,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel(
                            'USERNAME',
                            mutedColor,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            textInputAction:
                                TextInputAction.next,
                            autocorrect: false,
                            style: PaceUpTypography.body(
                              textColor,
                            ),
                            cursorColor:
                                PaceUpColors.electricGreen,
                            decoration: _inputDecoration(
                              hintText: 'your_username',
                              icon: Icons
                                  .alternate_email_rounded,
                              secondaryPanelColor:
                                  secondaryPanelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel(
                            'DISPLAY NAME',
                            mutedColor,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _displayNameController,
                            textInputAction:
                                TextInputAction.next,
                            style: PaceUpTypography.body(
                              textColor,
                            ),
                            cursorColor:
                                PaceUpColors.electricGreen,
                            decoration: _inputDecoration(
                              hintText: 'Your name',
                              icon: Icons.person_outline_rounded,
                              secondaryPanelColor:
                                  secondaryPanelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel(
                            'EMAIL',
                            mutedColor,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction:
                                TextInputAction.next,
                            autocorrect: false,
                            style: PaceUpTypography.body(
                              textColor,
                            ),
                            cursorColor:
                                PaceUpColors.electricGreen,
                            decoration: _inputDecoration(
                              hintText: 'you@example.com',
                              icon: Icons
                                  .alternate_email_rounded,
                              secondaryPanelColor:
                                  secondaryPanelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel(
                            'PASSWORD',
                            mutedColor,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction:
                                TextInputAction.done,
                            onSubmitted: (_) => _register(),
                            style: PaceUpTypography.body(
                              textColor,
                            ),
                            cursorColor:
                                PaceUpColors.electricGreen,
                            decoration: _inputDecoration(
                              hintText: 'Create a password',
                              icon: Icons.lock_outline_rounded,
                              secondaryPanelColor:
                                  secondaryPanelColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
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
                              onPressed:
                                  _isLoading ? null : _register,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    PaceUpColors.electricGreen,
                                foregroundColor:
                                    PaceUpColors.greenInk,
                                disabledBackgroundColor:
                                    PaceUpColors.electricGreen
                                        .withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 180,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        key: ValueKey(
                                          'loading',
                                        ),
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              PaceUpColors
                                                  .greenInk,
                                        ),
                                      )
                                    : Text(
                                        'CREATE ACCOUNT',
                                        key: const ValueKey(
                                          'create-account',
                                        ),
                                        style:
                                            PaceUpTypography
                                                .label(
                                          PaceUpColors
                                              .greenInk,
                                        ),
                                      ),
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
                          'ALREADY A MEMBER?',
                          style: PaceUpTypography.label(
                            mutedColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                PaceUpColors.electricGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'SIGN IN',
                            style: PaceUpTypography.label(
                              PaceUpColors.electricGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: PaceUpColors.electricGreen,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: PaceUpColors.electricGreen.withValues(
                alpha: 0.16,
              ),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_run_rounded,
          color: PaceUpColors.greenInk,
          size: 31,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String label,
    Color color,
  ) {
    return Text(
      label,
      style: PaceUpTypography.label(color),
    );
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
      hintStyle: PaceUpTypography.body(
        mutedColor,
      ),
      prefixIcon: Icon(
        icon,
        color: mutedColor,
        size: 19,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: secondaryPanelColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
        ),
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