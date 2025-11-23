import 'package:flutter/material.dart';
import 'package:dextera/repository/auth_repository.dart';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/screens/home_chat_screen.dart';

class OtpController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isResending => _isResending;
  String? get errorMessage => _errorMessage;

  Future<void> verifyOtp(String email, String otp, BuildContext context) async {
    if (otp.length != 6) {
      _errorMessage = 'Please enter a valid 6-digit OTP';
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = VerifyOtpRequest(email: email, otp: otp);
      final response = await _authRepository.verifyOtp(request);

      _isLoading = false;
      notifyListeners();

      if (response.status) {
        // Navigate to home screen
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeChatScreen()),
          );
        }
      } else {
        _errorMessage = response.message;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'OTP verification failed')),
        );
      }
    }
  }

  Future<void> resendOtp(String email, BuildContext context) async {
    _isResending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ResendOtpRequest(email: email);
      final response = await _authRepository.resendOtp(request);

      _isResending = false;
      notifyListeners();

      if (response.status) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      } else {
        _errorMessage = response.message;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      }
    } catch (e) {
      _isResending = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Failed to resend OTP')),
        );
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
