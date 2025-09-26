import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) return false;
      
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  static CameraController? get controller => _controller;
  static bool get isInitialized => _isInitialized;

  static Future<String?> takePicture() async {
    if (!_isInitialized || _controller == null) return null;
    
    try {
      final image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final savedPath = await LocalStorage.saveImage(bytes);
      await File(image.path).delete();
      return savedPath;
    } catch (e) {
      debugPrint('Take picture error: $e');
      return null;
    }
  }

  static Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    final currentIndex = _cameras!.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras!.length;
    
    await _controller!.dispose();
    _controller = CameraController(_cameras![nextIndex], ResolutionPreset.high);
    await _controller!.initialize();
  }

  static Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null) {
      await _controller!.setFlashMode(mode);
    }
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}