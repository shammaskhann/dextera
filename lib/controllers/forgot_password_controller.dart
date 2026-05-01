import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dextera/repository/auth_repository.dart';
import 'package:dextera/models/auth_models.dart';

class ForgotPasswordController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;
  String? _successMessage;

  // Field-specific errors
  String? _emailError;
  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Timer for resend OTP
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _canResendOtp = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get otpSent => _otpSent;
  bool get showPassword => _showPassword;
  bool get showConfirmPassword => _showConfirmPassword;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get emailError => _emailError;
  String? get otpError => _otpError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  int get resendCountdown => _resendCountdown;
  bool get canResendOtp => _canResendOtp;

  void validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (value.isEmpty) {
      _emailError = 'Email is required';
    } else if (!emailRegex.hasMatch(value)) {
      _emailError = 'Enter a valid email';
    } else {
      _emailError = null;
    }
    notifyListeners();
  }

  void validateOtp(String value) {
    if (value.isEmpty) {
      _otpError = 'OTP is required';
    } else if (value.length != 6) {
      _otpError = 'OTP must be 6 digits';
    } else if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      _otpError = 'OTP must contain only digits';
    } else {
      _otpError = null;
    }
    notifyListeners();
  }

  void validatePassword(String value) {
    if (value.isEmpty) {
      _passwordError = 'Password is required';
    } else if (value.length < 6) {
      _passwordError = 'At least 6 characters';
    } else {
      _passwordError = null;
    }
    notifyListeners();
  }

  void validateConfirmPassword(String value, String password) {
    if (value.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
    } else if (value != password) {
      _confirmPasswordError = 'Passwords do not match';
    } else {
      _confirmPasswordError = null;
    }
    notifyListeners();
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  void toggleShowConfirmPassword() {
    _showConfirmPassword = !_showConfirmPassword;
    notifyListeners();
  }

  void clearErrors() {
    _errorMessage = null;
    _emailError = null;
    _otpError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  void _startResendTimer() {
    _canResendOtp = false;
    _resendCountdown = 60;
    notifyListeners();

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendCountdown--;
      if (_resendCountdown <= 0) {
        _canResendOtp = true;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> sendOtp(String email, BuildContext context) async {
    // Validate email first
    validateEmail(email);
    if (_emailError != null) {
      _errorMessage = _emailError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = ForgotPasswordRequest(email: email);
      final response = await _authRepository.forgotPassword(request);

      _isLoading = false;

      if (response.status) {
        _otpSent = true;
        _successMessage = response.message;
        _startResendTimer();
        notifyListeners();
      } else {
        _errorMessage = response.message;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      log('Error sending OTP: $e');
    }
  }

  Future<void> resendOtp(String email, BuildContext context) async {
    if (!_canResendOtp) {
      _errorMessage = 'Please wait before requesting another OTP';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = ForgotPasswordRequest(email: email);
      final response = await _authRepository.forgotPassword(request);

      _isLoading = false;

      if (response.status) {
        _successMessage = 'OTP resent successfully';
        _startResendTimer();
        notifyListeners();
      } else {
        _errorMessage = response.message;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      log('Error resending OTP: $e');
    }
  }

  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    // Validate all fields
    validateOtp(otp);
    validatePassword(newPassword);
    validateConfirmPassword(confirmPassword, newPassword);

    if (_otpError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      if (_otpError != null) _errorMessage = _otpError;
      if (_passwordError != null) _errorMessage = _passwordError;
      if (_confirmPasswordError != null) _errorMessage = _confirmPasswordError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = ResetPasswordRequest(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      final response = await _authRepository.resetPassword(request);

      _isLoading = false;

      if (response.status) {
        _successMessage = 'Password reset successfully!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      log('Error resetting password: $e');
      return false;
    }
  }

  void resetState() {
    _otpSent = false;
    _showPassword = false;
    _showConfirmPassword = false;
    _errorMessage = null;
    _successMessage = null;
    _emailError = null;
    _otpError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _resendCountdown = 0;
    _canResendOtp = false;
    _resendTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
