import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MediaService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  static Future<Map<String, dynamic>> getMedia(String eventId) async {
    try {
      final response = await ApiService.get('/media/?event_id=$eventId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to load media: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching media: $e');
    }
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
    try {
      print('MediaService.uploadMedia called');
      print('Event ID: $eventId');
      print('File path: ${file.path}');
      print('Media type: $mediaType');

      // Validate file exists
      if (!await file.exists()) {
        return {
          'success': false,
          'error': 'File does not exist',
          'code': 'FILE_NOT_FOUND'
        };
      }
      
      final fields = {
        'event_id': eventId.trim(),
        'media_type': mediaType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split('/').last,
      );

      print(
          'Created multipart file: ${multipartFile.filename}, size: ${multipartFile.length}');

      final response = await ApiService.multipartRequest(
        'POST',
        '/media/upload/',
        fields,
        [multipartFile],
      );

      final responseBody = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      final data = jsonDecode(responseBody);

      // Handle success response (201 Created)
      if (response.statusCode == 201) {
        return data; // Return the full response as per API docs
      } else {
        // Handle error responses
        return {
          'success': false,
          'error': data['error'] ?? 'Upload failed',
          'code': data['code'] ?? 'UPLOAD_ERROR',
          'errors': data['errors'], // File-specific errors
          'details': data['details'],
        };
      }
    } catch (e) {
      print('Exception in uploadMedia: $e');
      return {
        'success': false,
        'error': 'Network or parsing error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  static Future<Map<String, dynamic>> uploadMultipleMedia({
    required String eventId,
    required List<File> files,
    required String mediaType,
    String? caption,
  }) async {
    try {
      print(
          'MediaService.uploadMultipleMedia called with ${files.length} files');

      // Validate files exist and limit to 20 files as per API docs
      if (files.length > 20) {
        return {
          'success': false,
          'error': 'Maximum 20 files allowed per bulk upload',
          'code': 'TOO_MANY_FILES'
        };
      }

      final validFiles = <File>[];
      for (final file in files) {
        if (await file.exists()) {
          validFiles.add(file);
        } else {
          print('File does not exist: ${file.path}');
        }
      }

      if (validFiles.isEmpty) {
        return {
          'success': false,
          'error': 'No valid files found',
          'code': 'NO_FILES'
        };
      }

      final fields = {
        'event_id': eventId.trim(),
        'media_type': mediaType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };

      final multipartFiles = <http.MultipartFile>[];
      for (final file in validFiles) {
        final multipartFile = await http.MultipartFile.fromPath(
          'files', // Use 'files' for bulk upload as per API docs
          file.path,
          filename: file.path.split('/').last,
        );
        multipartFiles.add(multipartFile);
      }

      // Use bulk-upload endpoint for multiple files
      final response = await ApiService.multipartRequest(
        'POST',
        '/media/bulk-upload/',
        fields,
        multipartFiles,
      );

      final responseBody = await response.stream.bytesToString();
      print('Bulk upload response status: ${response.statusCode}');
      print('Bulk upload response body: $responseBody');

      final data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        return data; // Return full response as per API docs
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Bulk upload failed',
          'code': data['code'] ?? 'UPLOAD_ERROR',
          'errors': data['errors'],
          'details': data['details'],
        };
      }
    } catch (e) {
      print('Exception in uploadMultipleMedia: $e');
      return {
        'success': false,
        'error': 'Network or parsing error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  static Future<Map<String, dynamic>> updateMedia(
    String mediaId, {
    String? caption,
  }) async {
    final response = await ApiService.patch('/media/$mediaId/', body: {
      if (caption != null) 'caption': caption,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteMedia(String mediaId) async {
    final response = await ApiService.delete('/media/$mediaId/');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      return {'success': false, 'error': 'Delete failed'};
    }
  }

  static Future<Map<String, dynamic>> uploadMediaFromXFile({
    required String eventId,
    required XFile xFile,
    required String mediaType,
    String? caption,
  }) async {
    try {
      print('Uploading single file: ${xFile.name}, type: $mediaType');

      final fields = {
        'event_id': eventId.trim(),
        'media_type': mediaType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };

      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) {
        return {'success': false, 'error': 'File is empty or corrupted'};
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: xFile.name,
      );

      final response = await ApiService.multipartRequest(
        'POST',
        '/media/upload/',
        fields,
        [multipartFile],
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('Upload timeout'),
      );

      final responseBody = await response.stream.bytesToString();
      print('Upload response: ${response.statusCode} - $responseBody');

      if (responseBody.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }

      final data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Upload failed',
          'code': data['code'] ?? 'UPLOAD_ERROR',
          'details': data['details'],
        };
      }
    } catch (e) {
      print('Upload exception: $e');
      return {
        'success': false,
        'error': e.toString().contains('timeout')
            ? 'Upload timeout - please try again'
            : 'Network error: $e',
        'code':
            e.toString().contains('timeout') ? 'TIMEOUT_ERROR' : 'NETWORK_ERROR'
      };
    }
  }

  static Future<Map<String, dynamic>> uploadMultipleMediaFromXFiles({
    required String eventId,
    required List<XFile> xFiles,
    String? caption,
  }) async {
    try {
      print('Uploading ${xFiles.length} files');

      if (xFiles.length > 20) {
        return {
          'success': false,
          'error': 'Maximum 20 files allowed per bulk upload',
          'code': 'TOO_MANY_FILES'
        };
      }

      // Determine media type from first file
      final firstFile = xFiles.first;
      final extension = firstFile.path.toLowerCase().split('.').last;
      final mediaType = ['jpg', 'jpeg', 'png', 'gif', 'JPG', 'webp', 'bmp']
              .contains(extension)
          ? 'image'
          : 'video';

      final fields = {
        'event_id': eventId.trim(),
        'media_type': mediaType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };

      final multipartFiles = <http.MultipartFile>[];
      for (final xFile in xFiles) {
        final bytes = await xFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: xFile.name,
        );
        multipartFiles.add(multipartFile);
      }

      final response = await ApiService.multipartRequest(
        'POST',
        '/media/bulk-upload/',
        fields,
        multipartFiles,
      );

      final responseBody = await response.stream.bytesToString();
      print('Bulk upload response: ${response.statusCode} - $responseBody');

      if (responseBody.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }

      final data = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Bulk upload failed',
          'code': data['code'] ?? 'UPLOAD_ERROR',
          'errors': data['errors'],
          'details': data['details'],
        };
      }
    } catch (e) {
      print('Bulk upload exception: $e');
      return {
        'success': false,
        'error': 'Exception: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  static Future<Map<String, dynamic>> uploadFilesWithFormData({
    required String eventId,
    required List<XFile> files,
    String? caption,
  }) async {
    http.Client? client;
    try {
      print('Uploading ${files.length} files with form data');

      if (files.isEmpty) {
        return {
          'success': false,
          'error': 'No files selected',
          'code': 'NO_FILES'
        };
      }

      if (files.length > 20) {
        return {
          'success': false,
          'error': 'Maximum 20 files allowed per upload',
          'code': 'TOO_MANY_FILES'
        };
      }

      // Use single upload endpoint for all uploads
      final uri = Uri.parse('${ApiService.baseUrl}/media/upload/');
      final request = http.MultipartRequest('POST', uri);
      client = http.Client();

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['event_id'] = eventId.trim();
      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      // Process each file with validation
      int validFileCount = 0;
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        print('Processing file $i: ${file.name}');

        try {
          final bytes = await file.readAsBytes();
          print('File $i bytes length: ${bytes.length}');

          if (bytes.isEmpty) {
            print('Warning: File $i is empty, skipping');
            continue;
          }

          if (bytes.length > 50 * 1024 * 1024) {
            print(
                'Warning: File $i is too large (${bytes.length} bytes), skipping');
            continue;
          }

          final extension = file.name.toLowerCase().split('.').last;
          final mediaType = ['jpg', 'jpeg', 'png', 'gif', 'JPG', 'webp', 'bmp']
                  .contains(extension)
              ? 'image'
              : 'video';

          if (validFileCount == 0) {
            request.fields['media_type'] = mediaType;
          }

          // Use 'file' for single, 'files' for multiple
          final fieldName = files.length == 1 ? 'file' : 'files';
          
          // Set correct MIME type based on extension
          String? contentType;
          switch (extension) {
            case 'jpg':
            case 'jpeg':
              contentType = 'image/jpeg';
              break;
            case 'png':
              contentType = 'image/png';
              break;
            case 'gif':
              contentType = 'image/gif';
              break;
            case 'webp':
              contentType = 'image/webp';
              break;
            case 'bmp':
              contentType = 'image/bmp';
              break;
            case 'mp4':
              contentType = 'video/mp4';
              break;
            case 'mov':
              contentType = 'video/quicktime';
              break;
            case 'avi':
              contentType = 'video/x-msvideo';
              break;
            case 'webm':
              contentType = 'video/webm';
              break;
          }
          
          final multipartFile = http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: file.name,
            contentType: contentType != null ? MediaType.parse(contentType) : null,
          );

          request.files.add(multipartFile);
          validFileCount++;
          print('Added file $i to request: ${file.name}');
        } catch (e) {
          print('Error processing file $i (${file.name}): $e');
        }
      }

      if (validFileCount == 0) {
        return {
          'success': false,
          'error': 'No valid files to upload',
          'code': 'NO_VALID_FILES'
        };
      }

      print('Sending request to: $uri');
      print('Request files count: ${request.files.length}');
      print('Request fields: ${request.fields}');
      for (int i = 0; i < request.files.length; i++) {
        print('File $i: field=${request.files[i].field}, filename=${request.files[i].filename}');
      }

      final response = await client.send(request).timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          throw Exception('Upload timeout - please check your connection');
        },
      );

      final responseBody = await response.stream.bytesToString();
      print('Upload response: ${response.statusCode}');
      print('Response body: $responseBody');

      if (responseBody.isEmpty) {
        return {
          'success': false,
          'error': 'Empty response from server',
          'code': 'EMPTY_RESPONSE'
        };
      }

      final data = jsonDecode(responseBody);
      print('Parsed response data: $data');

      if (response.statusCode == 201) {
        return data; // Return API response as-is
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Upload failed',
          'code': data['code'] ?? 'UPLOAD_ERROR',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      print('Upload exception: $e');
      final errorMessage = e.toString();
      return {
        'success': false,
        'error': errorMessage.contains('timeout')
            ? 'Upload timeout - please check your connection and try again'
            : 'Network error: $errorMessage',
        'code':
            errorMessage.contains('timeout') ? 'TIMEOUT_ERROR' : 'NETWORK_ERROR'
      };
    } finally {
      client?.close();
    }
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