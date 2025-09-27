import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/media_provider.dart';
import '../../../shared/models/media_item.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/utils/upload_helper.dart';

class CameraScreen extends StatefulWidget {
  final String eventId;

  const CameraScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool isLoading = false;
  bool flashEnabled = false;
  String cameraMode = 'photo';
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final success = await CameraService.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          isCameraInitialized && CameraService.controller != null
              ? CameraPreview(CameraService.controller!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          'Initializing Camera...',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    // Flash toggle
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          flashEnabled = !flashEnabled;
                        });
                        await CameraService.setFlashMode(
                          flashEnabled ? FlashMode.torch : FlashMode.off,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: flashEnabled 
                              ? const Color(0xFF6C63FF).withOpacity(0.8)
                              : Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          flashEnabled ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Camera mode selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeButton('PHOTO', 'photo'),
                          _buildModeButton('VIDEO', 'video'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Main controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery thumbnail
                        GestureDetector(
                          onTap: () => context.go('/event/${widget.eventId}/gallery'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A3E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Capture button
                        GestureDetector(
                          onTap: isLoading ? null : _capturePhoto,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: cameraMode == 'video' 
                                          ? Colors.red 
                                          : Colors.white,
                                      shape: cameraMode == 'video' 
                                          ? BoxShape.rectangle 
                                          : BoxShape.circle,
                                      borderRadius: cameraMode == 'video' 
                                          ? BorderRadius.circular(8) 
                                          : null,
                                    ),
                                  ),
                          ),
                        ),

                        // Switch camera button
                        GestureDetector(
                          onTap: () async {
                            await CameraService.switchCamera();
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final isSelected = cameraMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          cameraMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (!isCameraInitialized) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      String? filePath;
      MediaType mediaType;
      
      if (cameraMode == 'video') {
        // Video capture not implemented yet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video capture not implemented yet'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } else {
        filePath = await CameraService.takePicture();
        mediaType = MediaType.image;
      }
      
      if (filePath != null && mounted) {
        final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
        final success = await mediaProvider.addMediaItem(
          eventId: widget.eventId,
          filePath: filePath,
          type: mediaType,
        );
        
        if (success) {
          _showCaptureSuccess();
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            context.go('/event/${widget.eventId}/gallery');
          }
        } else {
          if (mounted) {
            final error = mediaProvider.uploadError ?? 'Upload failed';
            UploadHelper.showUploadError(context, error);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        UploadHelper.showUploadError(
          context, 
          'Failed to capture ${cameraMode == 'video' ? 'video' : 'photo'}: $e'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showCaptureSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
    
    // Auto dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}