import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthController authController;

  const ForgotPasswordScreen({
  super.key,
  required this.authController,
});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authController.forgotPassword(
  email: _emailController.text.trim(),
);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSent = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        foregroundColor: PaceUpColors.darkText,
        elevation: 0,
        title: Text(
          'FORGOT PASSWORD',
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
          child: _isSent
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
            'RESET YOUR PASSWORD',
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
            'Enter the email address linked to your PaceUp account. '
            'We will send you a link to reset your password.',
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkMuted,
            ).copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'EMAIL',
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkText,
            ),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: PaceUpTypography.bodyMedium(
                PaceUpColors.darkMuted,
              ),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: PaceUpColors.darkMuted,
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
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Email is required.';
              }

              if (!email.contains('@')) {
                return 'Enter a valid email address.';
              }

              return null;
            },
            onFieldSubmitted: (_) => _sendResetEmail(),
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
              onPressed: _isLoading ? null : _sendResetEmail,
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
                      'SEND RESET LINK',
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
            Icons.mark_email_read_outlined,
            color: PaceUpColors.electricGreen,
            size: 30,
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'CHECK YOUR EMAIL',
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
          'If an account exists for this email address, '
          'we have sent you a password reset link.',
          style: PaceUpTypography.bodyMedium(
            PaceUpColors.darkMuted,
          ).copyWith(
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PaceUpColors.darkPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PaceUpColors.darkBorder,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: PaceUpColors.electricCyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Check your spam or junk folder if you do not see the email.',
                  style: PaceUpTypography.bodyMedium(
                    PaceUpColors.darkMuted,
                  ).copyWith(
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: PaceUpColors.darkText,
              side: const BorderSide(
                color: PaceUpColors.darkBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'BACK TO SIGN IN',
              style: PaceUpTypography.bodyMedium(
                PaceUpColors.darkText,
              ).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
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