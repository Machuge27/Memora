import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/media_provider.dart';
import '../../../shared/models/media_item.dart';
import '../widgets/video_player_widget.dart';

class MediaDetailScreen extends StatefulWidget {
  final String mediaId;
  final List<String>? mediaIds; // List of all media IDs for navigation

  const MediaDetailScreen({
    super.key,
    required this.mediaId,
    this.mediaIds,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  bool _showUI = true;
  bool _isLiked = false;
  late PageController _pageController;
  int _currentIndex = 0;
  late TransformationController _transformationController;
  double _currentScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;
  bool _isMaximized = false;

  // Add margin constants for gesture detection
  static const double _gestureMargin = 40.0; // Margin from screen edges

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    if (widget.mediaIds != null) {
      _currentIndex = widget.mediaIds!.indexOf(widget.mediaId);
      _pageController = PageController(initialPage: _currentIndex);
    }
  }

  @override
  void dispose() {
    if (widget.mediaIds != null) {
      _pageController.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _navigateToNext() {
    if (widget.mediaIds != null && _currentIndex < widget.mediaIds!.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPrevious() {
    if (widget.mediaIds != null && _currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && widget.mediaIds != null) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _navigateToPrevious();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _navigateToNext();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            if (widget.mediaIds == null) {
              final mediaItem = mediaProvider.getMediaById(widget.mediaId);
              if (mediaItem == null) {
                return const Center(
                  child: Text(
                    'Media not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }
              return _buildSingleMediaView(mediaItem, mediaProvider);
            } else {
              return _buildMultiMediaView(mediaProvider);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMultiMediaView(MediaProvider mediaProvider) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // PageView with gesture handling disabled when zoomed
        PageView.builder(
          controller: _pageController,
          physics: _currentScale > 1.0
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
            _resetZoom();
            HapticFeedback.lightImpact();
          },
          itemCount: widget.mediaIds!.length,
          itemBuilder: (context, index) {
            final mediaItem = mediaProvider.getMediaById(widget.mediaIds![index]);
            if (mediaItem == null) return const SizedBox();
            return _buildMediaContent(mediaItem);
          },
        ),

        // Custom gesture overlay
        _buildGestureOverlay(),

        // Navigation arrows
        if (widget.mediaIds != null && widget.mediaIds!.length > 1)
          ..._buildNavigationArrows(),

        // UI Overlays
        _buildUIOverlays(mediaProvider),
      ],
    );
  }

  Widget _buildSingleMediaView(MediaItem mediaItem, MediaProvider mediaProvider) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildMediaContent(mediaItem),
        _buildGestureOverlay(),
        _buildUIOverlays(mediaProvider),
      ],
    );
  }

  Widget _buildGestureOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleUI,
        onPanUpdate: (details) {
          // Handle swipe gestures only when not zoomed
          if (_currentScale <= 1.0 && widget.mediaIds != null) {
            final screenWidth = MediaQuery.of(context).size.width;
            final dx = details.delta.dx;

            // Horizontal swipe detection with threshold
            if (dx.abs() > 2) {
              if (dx > 0 && _currentIndex > 0) {
                // Swipe right - previous
                _navigateToPrevious();
              } else if (dx < 0 &&
                  _currentIndex < widget.mediaIds!.length - 1) {
                // Swipe left - next
                _navigateToNext();
              }
            }
          }
        },
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond;

          // Vertical swipe gestures
          if (velocity.dy.abs() > velocity.dx.abs()) {
            if (velocity.dy < -500) {
              // Swipe up - show options
              final currentMediaId =
                  widget.mediaIds?[_currentIndex] ?? widget.mediaId;
              _showOptionsBottomSheet(context, currentMediaId);
            } else if (velocity.dy > 500) {
              // Swipe down - close
              Navigator.pop(context);
            }
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildMediaContent(MediaItem mediaItem) {
    if (mediaItem.mediaType == MediaType.video) {
      return _buildVideoView(mediaItem);
    }
    
    return Center(
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: _minScale,
        maxScale: _maxScale,
        panEnabled: _currentScale > 1.0, // Only allow panning when zoomed
        scaleEnabled: true,
        onInteractionStart: (details) {
          // Interaction started - zoom/pan mode
        },
        onInteractionEnd: (details) {
          // Interaction ended
        },
        onInteractionUpdate: (details) {
          setState(() {
            _currentScale = _transformationController.value.getMaxScaleOnAxis();
          });
        },
        child: mediaItem.fileUrl != null
            ? Image.network(
                mediaItem.fileUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 3,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load media',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 80),
                    SizedBox(height: 16),
                    Text(
                      'No media available',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVideoView(MediaItem mediaItem) {
    if (mediaItem.fileUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.white54, size: 80),
            SizedBox(height: 16),
            Text(
              'No video available',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return VideoPlayerWidget(
      videoUrl: mediaItem.fileUrl!,
      autoPlay: false,
      showControls: true,
    );
  }

  Widget _buildUIOverlays(MediaProvider mediaProvider) {
    final currentMediaId = widget.mediaIds != null 
        ? widget.mediaIds![_currentIndex] 
        : widget.mediaId;
    final mediaItem = mediaProvider.getMediaById(currentMediaId);
    
    if (mediaItem == null) return const SizedBox();

    return Stack(
      children: [
        // Top UI overlay
        if (_showUI)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showOptionsBottomSheet(context, currentMediaId),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom UI overlay
        if (_showUI)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: 'Like',
                          color: _isLiked ? Colors.red : Colors.white,
                          onTap: () {
                            setState(() {
                              _isLiked = !_isLiked;
                            });
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.close,
                          label: 'Close',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildActionButton(
                          icon: Icons.person_add,
                          label: 'Tag',
                          onTap: () => _showTagPeople(context),
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: () => _shareMedia(context),
                        ),
                      ],
                    ),
                    
                    if (mediaItem.caption != null && mediaItem.caption!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        mediaItem.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(mediaItem.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        // Photo counter
                        if (widget.mediaIds != null && widget.mediaIds!.length > 1) ...[
                          Text(
                            '${_currentIndex + 1} / ${widget.mediaIds!.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                        ],
                        const Icon(
                          Icons.visibility,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '24 views',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTagPeople(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tag people functionality would be implemented here'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, String mediaId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildBottomSheetItem(
              icon: Icons.edit,
              title: 'Edit Caption',
              onTap: () {
                Navigator.pop(context);
                _showEditCaptionDialog(context, mediaId);
              },
            ),
            _buildBottomSheetItem(
              icon: Icons.share,
              title: 'Share Photo',
              onTap: () {
                Navigator.pop(context);
                _shareMedia(context);
              },
            ),
            _buildBottomSheetItem(
              icon: Icons.download,
              title: 'Download',
              onTap: () {
                Navigator.pop(context);
                _downloadMedia(context);
              },
            ),
            _buildBottomSheetItem(
              icon: Icons.person_add,
              title: 'Tag People',
              onTap: () {
                Navigator.pop(context);
                _showTagPeople(context);
              },
            ),
            _buildBottomSheetItem(
              icon: Icons.report,
              title: 'Report',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildBottomSheetItem(
              icon: Icons.delete,
              title: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, mediaId);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: color, 
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showEditCaptionDialog(BuildContext context, String mediaId) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final mediaItem = mediaProvider.getMediaById(mediaId);
    
    if (mediaItem == null) return;

    final controller = TextEditingController(text: mediaItem.caption ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Caption',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter caption...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              mediaProvider.updateMediaCaption(mediaId, controller.text);
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String mediaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Photo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this photo? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
              final mediaItem = mediaProvider.getMediaById(mediaId);
              mediaProvider.deleteMediaItem(mediaId);
              Navigator.pop(context);
              
              if (widget.mediaIds != null && widget.mediaIds!.length > 1) {
                // If there are more media items, stay in detail view with updated list
                final updatedMediaIds = List<String>.from(widget.mediaIds!)
                  ..remove(mediaId);
                if (updatedMediaIds.isNotEmpty) {
                  final newIndex = _currentIndex >= updatedMediaIds.length
                      ? updatedMediaIds.length - 1
                      : _currentIndex;
                  context.pushReplacement('/media/${updatedMediaIds[newIndex]}',
                      extra: {'mediaIds': updatedMediaIds});
                } else {
                  // No more media, go back to gallery
                  context.go('/event/${mediaItem?.event?.id}/gallery');
                }
              } else {
                // Single media deleted, go back to gallery
                context.go('/event/${mediaItem?.event?.id}/gallery');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _shareMedia(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality would be implemented here'),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _downloadMedia(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Photo saved to gallery'),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  List<Widget> _buildNavigationArrows() {
    return [
      // Left arrow
      if (_currentIndex > 0)
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _navigateToPrevious,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      // Right arrow
      if (_currentIndex < widget.mediaIds!.length - 1)
        Positioned(
          right: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _navigateToNext,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}