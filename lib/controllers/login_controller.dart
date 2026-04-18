import 'dart:developer';

import 'package:dextera/screens/home_chat_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dextera/repository/auth_repository.dart';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Google Login failed')),
        );
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
        // Navigation handled in UI layer via errorMessage == null check
      } else {
        _errorMessage = response.message;
        notifyListeners();

        if (context != null && context.mounted) {
          log('Google login failed: ${response.message}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      }
    } catch (e) {
      log('Error during Google login process: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Google Login failed')),
        );
      }
    }
  }

  // ── Email / password login (unchanged) ───────────────────────────────────
  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Please fill in all fields';
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

      if (response.status && response.token.isNotEmpty) {
        TokenStore.token = response.token;
        if (context.mounted) {
          if (response.user?.verified ?? false) {
            Navigator.of(context).pushNamed('/chat');
          }
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
          SnackBar(content: Text(_errorMessage ?? 'Login failed')),
        );
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
