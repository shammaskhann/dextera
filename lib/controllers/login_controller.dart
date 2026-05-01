import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dextera/repository/auth_repository.dart';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:dextera/utils/user_store.dart';
import 'package:dextera/utils/snackbar_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  // Field-specific errors
  String? _emailError;
  String? _passwordError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

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

  bool validateAll(String email, String password) {
    validateEmail(email);
    validatePassword(password);
    return _emailError == null && _passwordError == null;
  }

  // ── Web: initialize + return the stream ──────────────────────────────────
  Stream<GoogleSignInAccount?>? initializeForWeb() {
    if (!kIsWeb) return null;

    GoogleSignIn.instance.initialize(
      clientId:
          '480055628662-0k16ncrv9f881j0se8va6el00tnajjk9.apps.googleusercontent.com',
    );

    return GoogleSignIn.instance.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .map((event) => (event as GoogleSignInAuthenticationEventSignIn).user);
  }

  // ── Mobile: tap-triggered flow ───────────────────────────────────────────
  Future<void> continueWithGoogle(BuildContext context) async {
    if (kIsWeb) return; // web uses renderButton — never call this on web

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await GoogleSignIn.instance.initialize(
        clientId:
            '480055628662-0k16ncrv9f881j0se8va6el00tnajjk9.apps.googleusercontent.com',
      );

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: ['email', 'profile', 'openid']);

      if (!context.mounted) return;
      await handleGoogleCredential(account, context: context);
    } catch (e) {
      log('Google Sign-In error: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (context.mounted) {
        CustomSnackBar.showError(context, error: e);
      }
    }
  }

  // ── Shared: process account → call API → store token ────────────────────
  Future<void> handleGoogleCredential(
    GoogleSignInAccount account, {
    BuildContext? context,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _isLoading = false;
        _errorMessage = 'Failed to retrieve Google ID token';
        notifyListeners();
        return;
      }

      final request = GoogleLoginRequest(idToken: idToken);
      log(request.toJson().toString());
      final response = await _authRepository.googleLogin(request);

      _isLoading = false;
      notifyListeners();

      if (response.status && response.token.isNotEmpty) {
        TokenStore.token = response.token;
        if (response.user != null) {
          UserStore.user = response.user;
        }
        // Navigation handled in UI layer via errorMessage == null check
      } else {
        _errorMessage = response.message;
        notifyListeners();

        if (context != null && context.mounted) {
          log('Google login failed: ${response.message}');
          CustomSnackBar.showError(context, error: response.message);
        }
      }
    } catch (e) {
      log('Error during Google login process: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();

      if (context != null && context.mounted) {
        CustomSnackBar.showError(context, error: e);
      }
    }
  }

  // ── Email / password login (unchanged) ───────────────────────────────────
  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    if (!validateAll(email, password)) {
      _errorMessage = 'Please fix the errors above';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authRepository.login(request);

      _isLoading = false;
      notifyListeners();
      if (response.user?.verified == false) {
        _errorMessage = 'Please verify your email before logging in';
        notifyListeners();
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            type: SnackBarType.info,
            message: 'Please verify your email before logging in',
          );
        }
        Navigator.of(context).pushNamed('/otp', arguments: email);
        //return;
      }

      if (response.status && response.token.isNotEmpty) {
        TokenStore.token = response.token;
        if (response.user != null) {
          UserStore.user = response.user;
        }
        if (context.mounted) {
          if (response.user?.verified ?? false) {
            Navigator.of(context).pushNamed('/chat');
          }
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
}
