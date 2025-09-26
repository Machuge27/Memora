import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../media/providers/media_provider.dart';
import '../../../shared/models/media_item.dart';

class DeviceGalleryScreen extends StatelessWidget {
  const DeviceGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Device Gallery',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                size: 60,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Media',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose photos or videos from your device\nto add to your gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            
            // Select Photos Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.photo, color: Colors.white),
                label: const Text(
                  'Select Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Select Videos Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _pickVideo(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.videocam, color: Color(0xFF6C63FF)),
                label: const Text(
                  'Select Videos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // View Gallery Button (appears when media exists)
            Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                final deviceMedia = mediaProvider.getMediaForEvent('device-gallery');
                if (deviceMedia.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3A3A4E)),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/gallery/device-gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.collections, color: Colors.white),
                    label: Text(
                      'View Gallery (${deviceMedia.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultipleMedia();
      
      if (images.isNotEmpty && context.mounted) {
        final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        );
        
        for (final image in images) {
          await mediaProvider.addMediaItem(
            eventId: 'device-gallery',
            filePath: image.path,
            type: MediaType.image,
          );
        }
        
        // Dismiss loading indicator
        if (context.mounted) {
          Navigator.pop(context);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${images.length} ${images.length == 1 ? 'photo' : 'photos'} to gallery'),
              backgroundColor: const Color(0xFF6C63FF),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photos: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null && context.mounted) {
        final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        );
        
        await mediaProvider.addMediaItem(
          eventId: 'device-gallery',
          filePath: video.path,
          type: MediaType.video,
        );
        
        // Dismiss loading indicator
        if (context.mounted) {
          Navigator.pop(context);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video added to gallery'),
              backgroundColor: Color(0xFF6C63FF),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}