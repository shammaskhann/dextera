import 'dart:developer';

import 'package:dextera/screens/components/custom_button.dart';
import 'package:dextera/screens/components/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:dextera/core/app_theme.dart';
import 'package:dextera/controllers/forgot_password_controller.dart';
import 'package:dextera/utils/snackbar_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _controller = ForgotPasswordController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (_controller.successMessage != null && mounted) {
      log('Success: ${_controller.successMessage}');
      CustomSnackBar.showSuccess(context, message: _controller.successMessage!);
      _controller.clearSuccessMessage();
    }
    if (_controller.errorMessage != null && mounted) {
      log('Error: ${_controller.errorMessage}');
      CustomSnackBar.showError(context, error: _controller.errorMessage!);
      _controller.clearErrors();
      setState(() {});
    }
  }

  Future<void> _handleSendOtp() async {
    await _controller.sendOtp(emailController.text.trim(), context);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleResendOtp() {
    _controller.resendOtp(emailController.text.trim(), context);
  }

  Future<void> _handleResetPassword() async {
    final success = await _controller.resetPassword(
      emailController.text.trim(),
      otpController.text.trim(),
      newPasswordController.text,
      confirmPasswordController.text,
    );

    if (success && mounted) {
      // Show success message
      CustomSnackBar.showSuccess(
        context,
        message: 'Password reset successfully!',
      );
      // Wait 2 seconds then navigate back to login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _backToLogin() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundClr,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final containerWidth = isMobile
              ? double.infinity
              : MediaQuery.of(context).size.width * 0.7;
          final horizontalPadding = isMobile ? 16.0 : 32.0;
          final titleFontSize = isMobile ? 28.0 : 32.0;
          final subtitleFontSize = isMobile ? 12.0 : 14.0;
          final spacing = isMobile ? 20.0 : 30.0;
          final smallSpacing = isMobile ? 8.0 : 10.0;
          final largeSpacing = isMobile ? 30.0 : 40.0;
          final buttonSpacing = isMobile ? 20.0 : 25.0;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: SizedBox(
                width: containerWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: spacing),
                    // Lock icon
                    Icon(Icons.lock_outline, size: 48, color: lightBlueClr),
                    SizedBox(height: smallSpacing),
                    Text(
                      "Forgot Your Password?",
                      style: TextStyle(
                        color: whiteClr,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: smallSpacing),
                    Text(
                      _controller.otpSent
                          ? "Enter the OTP sent to your email and set a new password"
                          : "Enter your email address and we'll send you an OTP to reset your password",
                      style: TextStyle(
                        color: whiteClr,
                        fontSize: subtitleFontSize,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: largeSpacing),

                    // Error message display
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        if (_controller.errorMessage != null &&
                            _controller.errorMessage!.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _controller.errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Success message display
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        if (_controller.successMessage != null &&
                            _controller.successMessage!.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _controller.successMessage!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Stage 1: Email Entry
                    if (!_controller.otpSent)
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return Column(
                            children: [
                              CustomTextField(
                                hint: "Enter your email address",
                                label: "Email Address",
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                errorText: _controller.emailError,
                                onChanged: (val) =>
                                    _controller.validateEmail(val),
                              ),
                              SizedBox(height: buttonSpacing),
                              CustomButton(
                                label: "Send OTP",
                                onTap: _handleSendOtp,
                                isPrimary: true,
                                isLoading: _controller.isLoading,
                              ),
                            ],
                          );
                        },
                      ),

                    // Stage 2: Password Reset
                    if (_controller.otpSent)
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return Column(
                            children: [
                              // OTP Field
                              CustomTextField(
                                hint: "Enter 6-digit OTP",
                                label: "OTP Code",
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                errorText: _controller.otpError,
                                onChanged: (val) =>
                                    _controller.validateOtp(val),
                              ),
                              SizedBox(height: spacing),

                              // New Password Field
                              _buildPasswordField(
                                controller: newPasswordController,
                                label: "New Password",
                                hint: "Enter new password",
                                errorText: _controller.passwordError,
                                showPassword: _controller.showPassword,
                                onToggle: _controller.toggleShowPassword,
                                onChanged: (val) =>
                                    _controller.validatePassword(val),
                              ),
                              SizedBox(height: spacing),

                              // Confirm Password Field
                              _buildPasswordField(
                                controller: confirmPasswordController,
                                label: "Confirm Password",
                                hint: "Re-enter new password",
                                errorText: _controller.confirmPasswordError,
                                showPassword: _controller.showConfirmPassword,
                                onToggle: _controller.toggleShowConfirmPassword,
                                onChanged: (val) =>
                                    _controller.validateConfirmPassword(
                                      val,
                                      newPasswordController.text,
                                    ),
                              ),
                              SizedBox(height: buttonSpacing),

                              // Reset Password Button
                              CustomButton(
                                label: "Reset Password",
                                onTap: _handleResetPassword,
                                isPrimary: true,
                                isLoading: _controller.isLoading,
                              ),
                              SizedBox(height: 12),

                              // Resend OTP Button (shown after countdown completes)
                              if (_controller.canResendOtp)
                                CustomButton(
                                  label: "Resend OTP",
                                  onTap: _handleResendOtp,
                                  isPrimary: false,
                                  isLoading: _controller.isLoading,
                                ),

                              // Resend OTP Timer
                              if (!_controller.canResendOtp &&
                                  _controller.resendCountdown > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Resend OTP in ${_controller.resendCountdown}s',
                                    style: TextStyle(
                                      color: whiteClr.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                    SizedBox(height: buttonSpacing),

                    // Back to Login Button
                    TextButton(
                      onPressed: _backToLogin,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: lightBlueClr, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Back to Login",
                            style: TextStyle(
                              color: lightBlueClr,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? errorText,
    required bool showPassword,
    required VoidCallback onToggle,
    required Function(String) onChanged,
  }) {
    final width = MediaQuery.of(context).size.width;
    bool isMobile = width < 600;
    final double fieldWidth = isMobile ? width * 0.85 : width * 0.6;

    return Container(
      width: fieldWidth,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: whiteClr.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? Colors.red.withOpacity(0.5)
                    : lightBlueClr.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    obscureText: !showPassword,
                    style: TextStyle(color: whiteClr, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: whiteClr,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
