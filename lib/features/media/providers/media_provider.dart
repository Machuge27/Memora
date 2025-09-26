import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  final List<MediaItem> _mediaItems = [];
  bool _isLoading = false;

  List<MediaItem> get mediaItems => List.unmodifiable(_mediaItems);
  bool get isLoading => _isLoading;

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
    _isLoading = true;
    notifyListeners();

    try {
      final mediaItem = MediaItem(
        id: const Uuid().v4(),
        type: type,
        caption: caption,
        taggedUsers: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _mediaItems.add(mediaItem);
      return true;
    } catch (e) {
      debugPrint('Error adding media item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMediaItem(String mediaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _mediaItems.removeWhere((item) => item.id == mediaId);
      return true;
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
      final index = _mediaItems.indexWhere((item) => item.id == mediaId);
      if (index != -1) {
        _mediaItems[index] = _mediaItems[index].copyWith(caption: caption);
        notifyListeners();
        return true;
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


  Future<bool> addMediaFromFile(String filePath, String eventId) async {
    final type = _getMediaTypeFromPath(filePath);
    return await addMediaItem(
      eventId: eventId,
      filePath: filePath,
      type: type,
    );
  }

  MediaType _getMediaTypeFromPath(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'];
    
    if (imageExtensions.contains(extension)) {
      return MediaType.image;
    } else if (videoExtensions.contains(extension)) {
      return MediaType.video;
    }
    return MediaType.image; // Default to image
  }

// Private method to save media items (implement according to your storage solution)
Future<void> _saveMediaItems() async {
  // Implement your storage logic here
  // This could be SharedPreferences, SQLite, Hive, etc.
}
}