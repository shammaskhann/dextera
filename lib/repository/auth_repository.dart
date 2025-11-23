import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/core/api_endpoint.dart' as api;

class AuthRepository {
  Future<ApiResponse> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(api.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log(jsonResponse.toString());
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        // Handle error response (e.g., 400 - Email already in use)
        return ApiResponse(
          status: jsonResponse['status'] ?? false,
          message: jsonResponse['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse(api.login);
      log(url.toString());
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log(jsonResponse.toString());
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Login failed');
      }
    } catch (e) {
      log(e.toString());
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(api.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log(jsonResponse.toString());
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        return ApiResponse(
          status: jsonResponse['status'] ?? false,
          message: jsonResponse['message'] ?? 'OTP verification failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> resendOtp(ResendOtpRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(api.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log(jsonResponse.toString());
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        return ApiResponse(
          status: jsonResponse['status'] ?? false,
          message: jsonResponse['message'] ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      return ApiResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
