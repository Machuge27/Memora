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
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  static Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String endpoint, {bool requiresAuth = true}) async {
    final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
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
      request.headers['Authorization'] = 'Token $token';
    }
    
    request.fields.addAll(fields);
    request.files.addAll(files);
    
    return await request.send();
  }
}