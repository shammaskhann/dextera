import 'package:flutter/material.dart';
import 'package:dextera/repository/auth_repository.dart';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:dextera/utils/snackbar_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  // Field-specific errors
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get usernameError => _usernameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;

  void validateUsername(String value) {
    if (value.isEmpty) {
      _usernameError = 'Username is required';
    } else if (value.length < 3) {
      _usernameError = 'At least 3 characters';
    } else {
      _usernameError = null;
    }
    notifyListeners();
  }

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
      _confirmPasswordError = 'Please confirm password';
    } else if (value != password) {
      _confirmPasswordError = 'Passwords do not match';
    } else {
      _confirmPasswordError = null;
    }
    notifyListeners();
  }

  bool validateAll(String username, String email, String password, String confirmPassword) {
    validateUsername(username);
    validateEmail(email);
    validatePassword(password);
    validateConfirmPassword(confirmPassword, password);

    return _usernameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> register(
    String username,
    String email,
    String password,
    String confirmPassword,
    BuildContext context,
  ) async {
    if (!validateAll(username, email, password, confirmPassword)) {
      _errorMessage = 'Please fix the errors above';
      notifyListeners();
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
          Navigator.of(context).pushNamed(
            '/otp',
            arguments: email,
          );
        }
      } else {
        _errorMessage = response.message;
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showError(context, error: response.message);
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (context.mounted) {
        CustomSnackBar.showError(context, error: e);
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
          ).pushNamedAndRemoveUntil(
            '/chat',
            (route) => false,
          );
        }
      } else {
        _errorMessage = response.message;
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.showError(context, error: response.message);
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (context.mounted) {
        CustomSnackBar.showError(context, error: e);
      }
    }
  }
}
