import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer';

class TokenStore {
  static const _key = 'dextera_auth_token';
  static String? _token;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_key);
      
      if (_token != null && _token!.isNotEmpty) {
        if (JwtDecoder.isExpired(_token!)) {
          log("Token is expired, clearing...");
          await clear();
        } else {
          log("Token is valid");
        }
      }
    } catch(e) {
      log("Error init TokenStore: $e");
    }
  }

  static String? get token => _token;

  static set token(String? value) {
    _token = value;
    _saveToken(value);
  }

  static Future<void> _saveToken(String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null || value.isEmpty) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, value);
      }
    } catch(e) {
      log("Error saving token: $e");
    }
  }

  static Future<void> clear() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch(e) {
      log("Error clearing token: $e");
    }
  }
}
