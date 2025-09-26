import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _mediaItemsKey = 'media_items';
  static const String _eventsKey = 'events';
  static const String _userPrefsKey = 'user_preferences';
  
  // Get application documents directory for storing images
  Future<Directory> get _appDocDir async {
    return await getApplicationDocumentsDirectory();
  }
  
  // Save image to local storage
  Future<String?> saveImage(Uint8List imageData, String fileName) async {
    try {
      final Directory appDir = await _appDocDir;
      final Directory mediaDir = Directory('${appDir.path}/media');
      
      // Create media directory if it doesn't exist
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      final String filePath = '${mediaDir.path}/$fileName';
      final File file = File(filePath);
      
      await file.writeAsBytes(imageData);
      return filePath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }
  
  // Save image from file path
  Future<String?> saveImageFromPath(String sourcePath, String newFileName) async {
    try {
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;
      
      final Directory appDir = await _appDocDir;
      final Directory mediaDir = Directory('${appDir.path}/media');
      
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      
      final String newPath = '${mediaDir.path}/$newFileName';
      await sourceFile.copy(newPath);
      
      return newPath;
    } catch (e) {
      debugPrint('Error copying image: $e');
      return null;
    }
  }
  
  // Delete image from local storage
  Future<bool> deleteImage(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
  
  // Check if image exists
  Future<bool> imageExists(String filePath) async {
    try {
      final File file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  // Save media items to SharedPreferences
  Future<bool> saveMediaItems(List<Map<String, dynamic>> mediaItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(mediaItems);
      return await prefs.setString(_mediaItemsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving media items: $e');
      return false;
    }
  }
  
  // Get media items from SharedPreferences
  Future<List<Map<String, dynamic>>> getMediaItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_mediaItemsKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting media items: $e');
      return [];
    }
  }
  
  // Save events to SharedPreferences
  Future<bool> saveEvents(List<Map<String, dynamic>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(events);
      return await prefs.setString(_eventsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving events: $e');
      return false;
    }
  }
  
  // Get events from SharedPreferences
  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_eventsKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting events: $e');
      return [];
    }
  }
  
  // Save user preferences
  Future<bool> saveUserPreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is String) {
        return await prefs.setString('${_userPrefsKey}_$key', value);
      } else if (value is int) {
        return await prefs.setInt('${_userPrefsKey}_$key', value);
      } else if (value is bool) {
        return await prefs.setBool('${_userPrefsKey}_$key', value);
      } else if (value is double) {
        return await prefs.setDouble('${_userPrefsKey}_$key', value);
      } else {
        return await prefs.setString('${_userPrefsKey}_$key', jsonEncode(value));
      }
    } catch (e) {
      debugPrint('Error saving user preference: $e');
      return false;
    }
  }
  
  // Get user preference
  Future<T?> getUserPreference<T>(String key, [T? defaultValue]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = '${_userPrefsKey}_$key';
      
      if (T == String) {
        return prefs.getString(prefKey) as T? ?? defaultValue;
      } else if (T == int) {
        return prefs.getInt(prefKey) as T? ?? defaultValue;
      } else if (T == bool) {
        return prefs.getBool(prefKey) as T? ?? defaultValue;
      } else if (T == double) {
        return prefs.getDouble(prefKey) as T? ?? defaultValue;
      } else {
        final String? jsonString = prefs.getString(prefKey);
        if (jsonString != null) {
          return jsonDecode(jsonString) as T;
        }
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('Error getting user preference: $e');
      return defaultValue;
    }
  }
  
  // Clear all media items
  Future<bool> clearAllMediaItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_mediaItemsKey);
    } catch (e) {
      debugPrint('Error clearing media items: $e');
      return false;
    }
  }
  
  // Clear all events
  Future<bool> clearAllEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_eventsKey);
    } catch (e) {
      debugPrint('Error clearing events: $e');
      return false;
    }
  }
  
  // Clear all stored data
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Directory appDir = await _appDocDir;
      final Directory mediaDir = Directory('${appDir.path}/media');
      
      // Clear SharedPreferences
      await prefs.clear();
      
      // Delete media directory
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      return false;
    }
  }
}