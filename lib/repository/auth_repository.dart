import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:dextera/models/auth_models.dart';
import 'package:dextera/core/api_endpoint.dart' as api;

class AuthRepository {
  Future<ApiResponse> register(RegisterRequest request) async {
    try {
      final body = jsonEncode(request.toJson());
      if (body.isEmpty || body == 'null') {
        throw Exception('Invalid request body');
      }

      final response = await http.post(
        Uri.parse(api.register),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log(jsonResponse.toString());
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        return ApiResponse(
          status: jsonResponse['status'] ?? false,
          message: jsonResponse['message'] ?? 'Registration failed',
        );
      }
    } on FormatException catch (e) {
      log('JSON parse error: $e');
      return ApiResponse(
        status: false,
        message: 'Invalid server response format',
      );
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        return ApiResponse(
          status: false,
          message: 'Network error: Request body invalid',
        );
      }
      return ApiResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse(api.login);
      final body = jsonEncode(request.toJson());
      if (body.isEmpty || body == 'null') {
        throw Exception('Invalid request body');
      }

      log(url.toString());
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log('Response body: ${response.body}');
      log(jsonResponse.toString(), name: 'jsonResponse REGISTER');
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Login failed');
      }
    } on FormatException catch (e) {
      log('JSON parse error: $e');
      throw Exception('Server returned invalid response format');
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        throw Exception('Network error: Invalid request body');
      }
      log(e.toString());
      rethrow;
    }
  }

  Future<LoginResponse> googleLogin(GoogleLoginRequest request) async {
    try {
      final url = Uri.parse(api.googleLogin);
      final body = jsonEncode(request.toJson());
      if (body.isEmpty || body == 'null') {
        throw Exception('Invalid request body');
      }

      log(url.toString());
      log(request.toJson().toString());
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      log(
        'Response status: ${response.statusCode}',
        name: 'Response status GOOGLE LOGIN',
      );
      log(
        'Response body: ${response.body}',
        name: 'Response body GOOGLE LOGIN',
      );

      // Check if response body is null or empty
      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log(jsonResponse.toString());
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Google login failed');
      }
    } on FormatException catch (e) {
      log('JSON parse error: $e');
      throw Exception('Server returned invalid response format');
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        throw Exception('Network error: Invalid request body');
      }
      log(e.toString());
      rethrow;
    }
  }

  Future<ApiResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final body = jsonEncode(request.toJson());
      if (body.isEmpty || body == 'null') {
        throw Exception('Invalid request body');
      }

      final response = await http.post(
        Uri.parse(api.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log('Response body: ${response.body}', name: 'Response body VERIFY OTP');
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        return ApiResponse(
          status: jsonResponse['status'] ?? false,
          message: jsonResponse['message'] ?? 'OTP verification failed',
        );
      }
    } on FormatException catch (e) {
      log('JSON parse error: $e');
      return ApiResponse(
        status: false,
        message: 'Invalid server response format',
      );
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        return ApiResponse(
          status: false,
          message: 'Network error: Invalid request',
        );
      }
      return ApiResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> resendOtp(ResendOtpRequest request) async {
    try {
      final body = jsonEncode(request.toJson());
      if (body.isEmpty || body == 'null') {
        throw Exception('Invalid request body');
      }

      final response = await http.post(
        Uri.parse(api.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      log('Response body: ${response.body}', name: 'Response body RESEND OTP');
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonResponse);
      } else {
        return ApiResponse(
          status: jsonResponse['status'] ?? false,
          message: jsonResponse['message'] ?? 'Failed to resend OTP',
        );
      }
    } on FormatException catch (e) {
      log('JSON parse error: $e');
      return ApiResponse(
        status: false,
        message: 'Invalid server response format',
      );
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        return ApiResponse(
          status: false,
          message: 'Network error: Invalid request',
        );
      }
      return ApiResponse(
        status: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
