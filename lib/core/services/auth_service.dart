import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final response = await ApiService.post('/auth/register/', body: {
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    }, requiresAuth: false);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await ApiService.post('/auth/verify-email/', body: {
      'email': email,
      'otp': otp,
    }, requiresAuth: false);

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['data']?['access'] != null) {
      await _saveToken(data['data']['access']);
      await _saveRefreshToken(data['data']['refresh']);
    }
    
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login/', body: {
      'username': username,
      'password': password,
    }, requiresAuth: false);

    final data = jsonDecode(response.body);
    print('Login response: $data'); // Debug
    
    if (response.statusCode == 200 && data['access'] != null) {
      await _saveToken(data['access']);
      await _saveRefreshToken(data['refresh']);
      print('Token saved: ${data['access']}'); // Debug
    }
    
    return data;
  }

  static Future<void> logout() async {
    await ApiService.post('/auth/logout/');
    await _clearToken();
  }

  static Future<Map<String, dynamic>> sendOTP({
    required String email,
    required String purpose,
  }) async {
    final response = await ApiService.post('/auth/send-otp/', body: {
      'email': email,
      'purpose': purpose,
    }, requiresAuth: false);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await ApiService.post('/auth/password-reset-confirm/', body: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    }, requiresAuth: false);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await ApiService.post('/auth/change-password/', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.get('/auth/profile/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final response = await ApiService.patch('/auth/profile/', body: {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    });

    return jsonDecode(response.body);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> getStoredRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await getStoredRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await ApiService.post('/auth/refresh/', body: {
      'refresh': refreshToken,
    }, requiresAuth: false);

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['access'] != null) {
      await _saveToken(data['access']);
      // Keep the same refresh token unless a new one is provided
      if (data['refresh'] != null) {
        await _saveRefreshToken(data['refresh']);
      }
    }
    
    return data;
  }
}