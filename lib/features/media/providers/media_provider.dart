import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:file_selector/file_selector.dart';
import '../../../shared/models/media_item.dart';
import '../../../core/services/media_service.dart';

class MediaProvider extends ChangeNotifier {
  final List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  String? _uploadError;
  int _uploadProgress = 0;
  int _totalFiles = 0;

  List<MediaItem> get mediaItems => List.unmodifiable(_mediaItems);
  bool get isLoading => _isLoading;
  String? get uploadError => _uploadError;
  int get uploadProgress => _uploadProgress;
  int get totalFiles => _totalFiles;
  


  List<MediaItem> getMediaForEvent(String eventId) {
    return _mediaItems.where((item) => item.event?.id == eventId).toList();
  }

  MediaItem? getMediaById(String mediaId) {
    try {
      return _mediaItems.firstWhere((item) => item.id == mediaId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addMediaItem({
    required String eventId,
    required String filePath,
    required MediaType type,
    String? caption,
    String? thumbnailPath,
  }) async {
    return await addMediaFromFile(filePath, eventId, caption: caption);
  }

  Future<bool> addMultipleMediaItems({
    required String eventId,
    required List<String> filePaths,
    String? caption,
  }) async {
    return await addMultipleMediaFromFiles(filePaths, eventId,
        caption: caption);
  }

  Future<void> loadMediaForEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Loading media for event: $eventId');
      final response = await MediaService.getMedia(eventId);
      debugPrint('Media response: $response');
      
      if (response['results'] != null) {
        final mediaList = response['results'] as List;
        debugPrint('Found ${mediaList.length} media items');

        // Remove existing media for this event
        _mediaItems.removeWhere((item) => item.event?.id == eventId);

        // Add new media items
        for (final mediaJson in mediaList) {
          try {
            final mediaItem = MediaItem.fromJson(mediaJson);
            _mediaItems.add(mediaItem);
            debugPrint('Added media item: ${mediaItem.id}');
          } catch (e) {
            debugPrint('Error parsing media item: $e');
            debugPrint('Media JSON: $mediaJson');
          }
        }
      } else {
        debugPrint('No results found in response');
      }
    } catch (e) {
      debugPrint('Error loading media: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMediaItem(String mediaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await MediaService.deleteMedia(mediaId);
      if (response['success'] == true) {
        _mediaItems.removeWhere((item) => item.id == mediaId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting media item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMediaCaption(String mediaId, String caption) async {
    try {
      final response =
          await MediaService.updateMedia(mediaId, caption: caption);

      if (response['success'] == true) {
        final index = _mediaItems.indexWhere((item) => item.id == mediaId);
        if (index != -1) {
          _mediaItems[index] = _mediaItems[index].copyWith(caption: caption);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error updating media caption: $e');
      return false;
    }
  }
  // Add these methods to your MediaProvider class

// Method to get all events with their media grouped
Map<String, List<MediaItem>> getEventGroups() {
  final Map<String, List<MediaItem>> eventGroups = {};
  
  for (final mediaItem in _mediaItems) {
    final eventId = mediaItem.event?.id;
    if (eventId != null) {
      if (eventGroups.containsKey(eventId)) {
        eventGroups[eventId]!.add(mediaItem);
      } else {
        eventGroups[eventId] = [mediaItem];
      }
    }
  }
  
  // Sort media items within each event by creation date (newest first)
  for (final eventId in eventGroups.keys) {
    eventGroups[eventId]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  return eventGroups;
}

// Method to get all media items across all events
List<MediaItem> getAllMedia() {
  return List.from(_mediaItems);
}


  Future<bool> addMediaFromFile(String filePath, String eventId,
      {String? caption}) async {
    _isLoading = true;
    _uploadError = null;
    notifyListeners();

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _uploadError = 'File not found';
        return false;
      }

      final mediaType = _getMediaTypeFromPath(filePath) == MediaType.image
          ? 'image'
          : 'video';

      final response = await MediaService.uploadMedia(
        eventId: eventId,
        file: file,
        mediaType: mediaType,
        caption: caption,
      );

      if (response['success'] == true || response.containsKey('id')) {
        await loadMediaForEvent(eventId);
        return true;
      } else {
        _uploadError = response['error'] ?? 'Upload failed';
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      _uploadError = 'Upload failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMultipleMediaFromFiles(List<String> filePaths, String eventId,
      {String? caption}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (filePaths.isEmpty) return false;

      final file = File(filePaths.first);
      if (!await file.exists()) return false;

      final mediaType =
          _getMediaTypeFromPath(filePaths.first) == MediaType.image
              ? 'image'
              : 'video';

      final response = await MediaService.uploadMedia(
        eventId: eventId,
        file: file,
        mediaType: mediaType,
        caption: caption,
      );

      return response['success'] == true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMultipleMediaFromXFiles({
    required String eventId,
    required List<XFile> xFiles,
    String? caption,
  }) async {
    _isLoading = true;
    _uploadError = null;
    _totalFiles = xFiles.length;
    _uploadProgress = 0;
    notifyListeners();

    try {
      final response = await MediaService.uploadFilesWithFormData(
        eventId: eventId,
        files: xFiles,
        caption: caption,
      );
      
      debugPrint('Upload response: $response');
      
      // Check for success based on API response structure
      // API returns 201 with 'uploaded' array on success
      if (response.containsKey('uploaded') || response['success'] == true) {
        final uploadedCount = response['uploaded_count'] ?? response['uploaded']?.length ?? 0;
        _uploadProgress = uploadedCount;
        notifyListeners();
        
        // Reload media to show new uploads
        await loadMediaForEvent(eventId);
        return true;
      } else {
        _uploadError = response['error'] ?? 'Upload failed';
        debugPrint('Upload failed: $_uploadError');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading files: $e');
      _uploadError = 'Upload failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  

  


  MediaType _getMediaTypeFromPath(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'JPG', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'];
    
    if (imageExtensions.contains(extension)) {
      return MediaType.image;
    } else if (videoExtensions.contains(extension)) {
      return MediaType.video;
    }
    return MediaType.image; // Default to image
  }

  void clearError() {
    _uploadError = null;
    notifyListeners();
  }

  void resetUploadProgress() {
    _uploadProgress = 0;
    _totalFiles = 0;
    _uploadError = null;
    notifyListeners();
  }

// Private method to save media items (implement according to your storage solution)
Future<void> _saveMediaItems() async {
  // Implement your storage logic here
  // This could be SharedPreferences, SQLite, Hive, etc.
}
}