import 'package:flutter/material.dart';
import 'package:dextera/repository/auth_repository.dart';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/screens/otp_verify_screen.dart';
import 'package:dextera/screens/home_chat_screen.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> register(
    String username,
    String email,
    String password,
    String confirmPassword,
    BuildContext context,
  ) async {
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
      return;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
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
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
      );
      final response = await _authRepository.register(request);

      _isLoading = false;
      notifyListeners();

      if (response.status) {
        // Navigate to OTP verification screen
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(email: email),
            ),
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
          SnackBar(content: Text(_errorMessage ?? 'Registration failed')),
        );
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> continueWithGoogle(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await GoogleSignIn.instance.initialize(
        clientId: '377653791909-fuaevfuam21k8iffjaaf198rbf6eiiro.apps.googleusercontent.com',
      );

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _isLoading = false;
        _errorMessage = 'Failed to retrieve Google ID token';
        notifyListeners();
        return;
      }

      final request = GoogleLoginRequest(idToken: idToken);
      final response = await _authRepository.googleLogin(request);

      _isLoading = false;
      notifyListeners();

      if (response.status && response.token.isNotEmpty) {
        TokenStore.token = response.token;
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeChatScreen()),
            (route) => false,
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
          SnackBar(content: Text(_errorMessage ?? 'Google Signup failed')),
        );
      }
    }
  }
}
