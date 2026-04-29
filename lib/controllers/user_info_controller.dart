import 'dart:developer';
import 'package:get/get.dart';
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:dextera/utils/user_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dextera/core/api_endpoint.dart' as api;

class UserInfoController extends GetxController {
  final isUserNameLoading = false.obs;
  final isPasswordLoading = false.obs;

  final errorMessage = Rx<String?>(null);
  final successMessage = Rx<String?>(null);

  // Username validation
  final usernameError = Rx<String?>(null);
  final passwordError = Rx<String?>(null);
  final confirmPasswordError = Rx<String?>(null);

  void validateUsername(String value) {
    if (value.isEmpty) {
      usernameError.value = 'Username is required';
    } else if (value.length < 3) {
      usernameError.value = 'Username must be at least 3 characters';
    } else {
      usernameError.value = null;
    }
  }

  void validatePassword(String value) {
    if (value.isEmpty) {
      passwordError.value = 'Password is required';
    } else if (value.length < 6) {
      passwordError.value = 'At least 6 characters';
    } else {
      passwordError.value = null;
    }
  }

  void validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Please confirm password';
    } else if (password != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match';
    } else {
      confirmPasswordError.value = null;
    }
  }

  bool validateUsernameForm(String username) {
    validateUsername(username);
    return usernameError.value == null;
  }

  bool validatePasswordForm(String password, String confirmPassword) {
    validatePassword(password);
    validateConfirmPassword(password, confirmPassword);
    return passwordError.value == null && confirmPasswordError.value == null;
  }

  Future<bool> updateUsername(String newUsername) async {
    if (!validateUsernameForm(newUsername)) {
      errorMessage.value = 'Please fix the errors above';
      return false;
    }

    isUserNameLoading.value = true;
    errorMessage.value = null;
    successMessage.value = null;

    try {
      final token = TokenStore.token;
      if (token == null || token.isEmpty) {
        errorMessage.value = 'No authentication token found';
        isUserNameLoading.value = false;
        return false;
      }

      final response = await http
          .post(
            Uri.parse(api.updateUsername),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'userName': newUsername}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out'),
          );

      isUserNameLoading.value = false;

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == true) {
          successMessage.value = 'Username updated successfully';
          // Update local user info if backend returns the user object
          final currentUser = await UserStore.getUser();
          if (currentUser != null) {
            User? updatedUser;
            if (data['data'] != null) {
              updatedUser = User.fromJson(data['data']);
            } else {
              updatedUser = User(
                id: currentUser.id,
                name: newUsername,
                email: currentUser.email,
                mailLoggedIn: currentUser.mailLoggedIn,
                verified: currentUser.verified,
                createdAt: currentUser.createdAt,
                updatedAt: DateTime.now(),
              );
            }
            UserStore.saveUser(updatedUser);
          }
          return true;
        } else {
          errorMessage.value = data['message'] ?? 'Failed to update username';
          return false;
        }
      } else {
        errorMessage.value =
            data['message'] ??
            'Failed to update username (${response.statusCode})';
        return false;
      }
    } catch (e) {
      log('Error updating username: $e');
      errorMessage.value = 'Error updating username: $e';
      isUserNameLoading.value = false;
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    // We pass newPassword twice because confirmPassword check is already done in UI
    // but validatePasswordForm expects two arguments.
    if (!validatePasswordForm(newPassword, newPassword)) {
      errorMessage.value = 'Please fix the errors above';
      return false;
    }

    isPasswordLoading.value = true;
    errorMessage.value = null;
    successMessage.value = null;

    try {
      final token = TokenStore.token;
      if (token == null || token.isEmpty) {
        errorMessage.value = 'No authentication token found';
        isPasswordLoading.value = false;
        return false;
      }

      final response = await http
          .post(
            Uri.parse(api.updatePassword),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'password': newPassword}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out'),
          );

      isPasswordLoading.value = false;

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == true) {
          successMessage.value = 'Password updated successfully';

          // Update local user if needed (though password isn't stored in User object)
          if (data['data'] != null) {
            UserStore.user = User.fromJson(data['data']);
          }

          return true;
        } else {
          errorMessage.value = data['message'] ?? 'Failed to update password';
          return false;
        }
      } else {
        errorMessage.value =
            data['message'] ??
            'Failed to update password (${response.statusCode})';
        return false;
      }
    } catch (e) {
      log('Error updating password: $e');
      errorMessage.value = 'Error updating password: $e';
      isPasswordLoading.value = false;
      return false;
    }
  }

  void clearMessages() {
    errorMessage.value = null;
    successMessage.value = null;
  }
}
