import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/auth_state.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final AuthController authController;
  final String token;

  const VerifyEmailScreen({
    super.key,
    required this.authController,
    required this.token,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      await widget.authController.verifyEmail(token: widget.token);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isVerified = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
          'EMAIL VERIFICATION',
          style: PaceUpTypography.heading(PaceUpColors.darkText).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: _isLoading
              ? _buildLoadingState()
              : _isVerified
              ? _buildSuccessState()
              : _buildErrorState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(Icons.mark_email_unread_outlined),
        const SizedBox(height: 28),
        Text(
          'VERIFYING YOUR EMAIL',
          style: PaceUpTypography.heading(PaceUpColors.darkText).copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please wait while we verify your PaceUp email address.',
          style: PaceUpTypography.bodyMedium(PaceUpColors.darkMuted)
              .copyWith(height: 1.5),
        ),
        const SizedBox(height: 32),
        const Center(
          child: CircularProgressIndicator(color: PaceUpColors.electricGreen),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(Icons.mark_email_read_outlined),
        const SizedBox(height: 28),
        Text(
          'EMAIL VERIFIED',
          style: PaceUpTypography.heading(PaceUpColors.darkText).copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your email address has been successfully verified. '
          'Your PaceUp account is ready to use.',
          style: PaceUpTypography.bodyMedium(PaceUpColors.darkMuted)
              .copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildInfoPanel(
          Icons.check_circle_outline_rounded,
          'Your email is now verified.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      LoginScreen(authController: widget.authController),
                ),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: PaceUpColors.electricGreen,
              foregroundColor: PaceUpColors.greenInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'CONTINUE',
              style: PaceUpTypography.bodyMedium(PaceUpColors.greenInk)
                  .copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(Icons.error_outline_rounded, isError: true),
        const SizedBox(height: 28),
        Text(
          'VERIFICATION FAILED',
          style: PaceUpTypography.heading(PaceUpColors.darkText).copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'We could not verify your email address.',
          style: PaceUpTypography.bodyMedium(PaceUpColors.darkMuted)
              .copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildInfoPanel(
          Icons.info_outline_rounded,
          'The verification link may have expired or already been used.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _verifyEmail,
            style: OutlinedButton.styleFrom(
              foregroundColor: PaceUpColors.darkText,
              side: const BorderSide(color: PaceUpColors.darkBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'TRY AGAIN',
              style: PaceUpTypography.bodyMedium(PaceUpColors.darkText)
                  .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, {bool isError = false}) {
    final iconColor = isError
        ? PaceUpColors.danger
        : PaceUpColors.electricGreen;

    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: iconColor, size: 30),
    );
  }

  Widget _buildInfoPanel(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaceUpColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: PaceUpColors.electricCyan),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: PaceUpTypography.bodyMedium(PaceUpColors.darkMuted)
                  .copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
