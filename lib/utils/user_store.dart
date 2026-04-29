import 'dart:developer';
import 'dart:convert';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/utils/shared_storage.dart';

class UserStore {
  static const _key = 'dextera_user_info';
  static User? _user;

  static Future<void> init() async {
    try {
      final userJson = await getUserPlatform(_key);
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(userJson);
        _user = User.fromJson(decoded);
        log("User info loaded from storage");
      }
    } catch (e) {
      log("Error initializing UserStore: $e");
    }
  }

  static User? get user => _user;

  static set user(User? value) {
    _user = value;
    _saveUser(value);
  }

  static Future<User?> getUser() async {
    try {
      await init();
      return user;
    } catch (e) {
      log("Error getting user: $e");
      return null;
    }
  }

  static Future<void> _saveUser(User? value) async {
    try {
      if (value == null) {
        await removeUserPlatform(_key);
      } else {
        final json = jsonEncode({
          'id': value.id,
          'name': value.name,
          'email': value.email,
          'mailLoggedIn': value.mailLoggedIn,
          'verified': value.verified,
          'createdAt': value.createdAt?.toIso8601String(),
          'updatedAt': value.updatedAt?.toIso8601String(),
        });
        await saveUserPlatform(_key, json);
      }
    } catch (e) {
      log("Error saving user info: $e");
    }
  }

  static Future<void> saveUser(User user) async {
    user = user;
    saveUserPlatform(
      _key,
      jsonEncode({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'mailLoggedIn': user.mailLoggedIn,
        'verified': user.verified,
        'createdAt': user.createdAt?.toIso8601String(),
        'updatedAt': user.updatedAt?.toIso8601String(),
      }),
    );
  }

  static Future<void> clear() async {
    _user = null;
    try {
      await removeUserPlatform(_key);
    } catch (e) {
      log("Error clearing user info: $e");
    }
  }

  static Future<void> updateUser(User updatedUser) async {
    user = updatedUser;
  }
}
