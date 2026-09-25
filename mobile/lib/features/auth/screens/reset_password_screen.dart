import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/auth_state.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final AuthController authController;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.authController,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authController.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _backToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authController: widget.authController,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        foregroundColor: PaceUpColors.darkText,
        elevation: 0,
        title: Text(
          'RESET PASSWORD',
          style: PaceUpTypography.heading(
            PaceUpColors.darkText,
          ).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: _isSuccess
              ? _buildSuccessState()
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: PaceUpColors.electricGreen.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: PaceUpColors.electricGreen.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: PaceUpColors.electricGreen,
              size: 30,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'CREATE NEW PASSWORD',
            style: PaceUpTypography.heading(
              PaceUpColors.darkText,
            ).copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Choose a new password for your PaceUp account.',
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkMuted,
            ).copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'NEW PASSWORD',
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkText,
            ),
            decoration: InputDecoration(
              hintText: 'Enter new password',
              hintStyle: PaceUpTypography.bodyMedium(
                PaceUpColors.darkMuted,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: PaceUpColors.darkMuted,
              ),
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
                  color: PaceUpColors.darkMuted,
                ),
              ),
              filled: true,
              fillColor: PaceUpColors.darkPanel,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.darkBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.electricGreen,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.danger,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.danger,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              final password = value ?? '';

              if (password.isEmpty) {
                return 'Password is required.';
              }

              if (password.length < 8) {
                return 'Password must be at least 8 characters.';
              }

              return null;
            },
          ),

          const SizedBox(height: 18),

          Text(
            'CONFIRM PASSWORD',
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkText,
            ),
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              hintStyle: PaceUpTypography.bodyMedium(
                PaceUpColors.darkMuted,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: PaceUpColors.darkMuted,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: PaceUpColors.darkMuted,
                ),
              ),
              filled: true,
              fillColor: PaceUpColors.darkPanel,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.darkBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.electricGreen,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.danger,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PaceUpColors.danger,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              final password = value ?? '';

              if (password.isEmpty) {
                return 'Please confirm your password.';
              }

              if (password != _passwordController.text) {
                return 'Passwords do not match.';
              }

              return null;
            },
            onFieldSubmitted: (_) => _resetPassword(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: FilledButton.styleFrom(
                backgroundColor: PaceUpColors.electricGreen,
                foregroundColor: PaceUpColors.greenInk,
                disabledBackgroundColor:
                    PaceUpColors.electricGreen.withValues(
                  alpha: 0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: PaceUpColors.greenInk,
                      ),
                    )
                  : Text(
                      'RESET PASSWORD',
                      style: PaceUpTypography.bodyMedium(
                        PaceUpColors.greenInk,
                      ).copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: PaceUpColors.electricGreen.withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: PaceUpColors.electricGreen.withValues(
                alpha: 0.25,
              ),
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: PaceUpColors.electricGreen,
            size: 34,
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'PASSWORD UPDATED',
          style: PaceUpTypography.heading(
            PaceUpColors.darkText,
          ).copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Your PaceUp password has been successfully updated.',
          style: PaceUpTypography.bodyMedium(
            PaceUpColors.darkMuted,
          ).copyWith(
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _backToSignIn,
            style: FilledButton.styleFrom(
              backgroundColor: PaceUpColors.electricGreen,
              foregroundColor: PaceUpColors.greenInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'BACK TO SIGN IN',
              style: PaceUpTypography.bodyMedium(
                PaceUpColors.greenInk,
              ).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaceUpColors.danger.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PaceUpColors.danger.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: PaceUpColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: PaceUpTypography.bodyMedium(
                PaceUpColors.darkText,
              ).copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}