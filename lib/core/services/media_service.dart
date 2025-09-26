import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class MediaService {
  static Future<Map<String, dynamic>> getMedia(String eventId) async {
    final response = await ApiService.get('/media/?event_id=$eventId');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMediaItem(String mediaId) async {
    final response = await ApiService.get('/media/$mediaId/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadMedia({
    required String eventId,
    required File file,
    required String mediaType,
    String? caption,
  }) async {
    final fields = {
      'event_id': eventId,
      'media_type': mediaType,
      if (caption != null) 'caption': caption,
    };

    final multipartFile = await http.MultipartFile.fromPath('file', file.path);
    
    final response = await ApiService.multipartRequest(
      'POST',
      '/media/upload/',
      fields,
      [multipartFile],
    );

    final responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }

  static Future<Map<String, dynamic>> updateMedia(
    String mediaId, {
    String? caption,
  }) async {
    final response = await ApiService.put('/media/$mediaId/', body: {
      if (caption != null) 'caption': caption,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteMedia(String mediaId) async {
    final response = await ApiService.delete('/media/$mediaId/');
    return response.statusCode == 204 ? {'success': true} : jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMyMedia() async {
    final response = await ApiService.get('/media/my-media/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> tagUser(String mediaId, int userId) async {
    final response = await ApiService.post('/media/$mediaId/tag/', body: {
      'user_id': userId,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> untagUser(String mediaId, int userId) async {
    final response = await ApiService.delete('/media/$mediaId/untag/$userId/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> shareMedia(
    String mediaId,
    int userId, {
    String? message,
  }) async {
    final response = await ApiService.post('/media/$mediaId/share/', body: {
      'user_id': userId,
      if (message != null) 'message': message,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTaggedMedia() async {
    final response = await ApiService.get('/media/tagged/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getSharedMedia() async {
    final response = await ApiService.get('/media/shared/');
    return jsonDecode(response.body);
  }
}