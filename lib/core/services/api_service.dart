import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  static const String baseUrl = 'http://192.168.11.2:8000/api'; // iOS simulator
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Map<String, String> _getHeaders({bool requiresAuth = true}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _makeRequest(Future<http.Response> Function() request, {bool requiresAuth = true}) async {
    if (!requiresAuth) {
      return await request();
    }

    var response = await request();
    
    // If token expired, try to refresh and retry
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        response = await request();
      }
    }
    
    return response;
  }

  static Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    return await _makeRequest(() async {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 30));
    }, requiresAuth: requiresAuth);
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return await _makeRequest(() async {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
    }, requiresAuth: requiresAuth);
  }

  static Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return await _makeRequest(() async {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      return await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }, requiresAuth: requiresAuth);
  }

  static Future<http.Response> delete(String endpoint, {bool requiresAuth = true}) async {
    return await _makeRequest(() async {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    }, requiresAuth: requiresAuth);
  }

  static Future<http.StreamedResponse> multipartRequest(
    String method,
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$endpoint'));
    final token = await _getToken();
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields.addAll(fields);
    request.files.addAll(files);
    
    final client = http.Client();
    try {
      return await client.send(request).timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
    } finally {
      client.close();
    }
  }
}