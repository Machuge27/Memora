import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/media_provider.dart';
import '../../../shared/models/media_item.dart';
import '../../../core/services/media_service.dart';
import 'dart:io';
import '../../../shared/widgets/responsive_layout.dart';
import '../../events/providers/event_provider.dart';
import '../../../shared/models/event.dart';
import '../../../core/theme/theme_provider.dart';
import '../../events/widgets/event_header.dart';
import '../../events/widgets/event_options_menu.dart';

class MediaGalleryScreen extends StatefulWidget {
  final String eventId;

  const MediaGalleryScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  Event? event;
  bool isLoadingEvent = true;
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;
  bool _isHeaderCollapsed = false;
  
  static const double _maxHeaderHeight = 280.0;
  static const double _minHeaderHeight = 100.0;
  static const double _filterTabHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _loadMedia();
    _setupScrollController();
    _setupAnimations();
  }

  void _setupScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _onScroll() {
    const scrollThreshold = 50.0;
    final isScrolledPastThreshold = _scrollController.offset > scrollThreshold;
    
    if (isScrolledPastThreshold && !_isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = true);
      _headerAnimationController.forward();
    } else if (!isScrolledPastThreshold && _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = false);
      _headerAnimationController.reverse();
    }
  }

  Future<void> _loadEvent() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final loadedEvent = await eventProvider.getEventById(widget.eventId);
    if (mounted) {
      setState(() {
        event = loadedEvent;
        isLoadingEvent = false;
      });
    }
  }

  Future<void> _loadMedia() async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    await mediaProvider.loadMediaForEvent(widget.eventId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
      body: ResponsiveLayout(
        child: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            final allMediaItems = mediaProvider.getMediaForEvent(widget.eventId);
            final mediaItems = _filterMediaItems(allMediaItems);

            if (mediaItems.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: _buildEmptyState(),
                  );
            }

            return Stack(
              children: [
                // Main Content with Custom Scroll View
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Collapsible Header
                    SliverPersistentHeader(
                      pinned: false,
                      floating: false,
                      delegate: _HeaderDelegate(
                        event: event,
                        maxHeight: _maxHeaderHeight,
                        minHeight: _minHeaderHeight,
                        eventId: widget.eventId,
                        isLoading: isLoadingEvent,
                      ),
                    ),
                    
                    // Content spacing for filter tabs
                    const SliverToBoxAdapter(
                      child: SizedBox(height: _filterTabHeight),
                    ),
                    
                    // Gallery Grid
                    SliverPadding(
                          padding: const EdgeInsets.all(10),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getGridColumns(context),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final mediaItem = mediaItems[index];
                                final mediaIds =
                                    mediaItems.map((item) => item.id).toList();
                            return _MediaGridItem(
                              mediaItem: mediaItem,
                              onTap: () => context.push(
                                    '/media/${mediaItem.id}',
                                    extra: {
                                      'mediaIds': mediaIds,
                                    },
                              ),
                            );
                          },
                          childCount: mediaItems.length,
                        ),
                      ),
                    ),
                    
                    // Bottom padding for FAB
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
                
                // Sticky Filter Tabs
                AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _isHeaderCollapsed 
                          ? MediaQuery.of(context).padding.top
                          : _maxHeaderHeight - (_headerAnimation.value * 50),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _filterTabHeight,
                        decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(
                            _isHeaderCollapsed ? 0.95 : 0.8,
                          ),
                          border: Border(
                            bottom: BorderSide(
                                  color: theme.colorScheme.outline.withOpacity(
                                _isHeaderCollapsed ? 1.0 : 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildFilterTabs(allMediaItems),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Stack(
      children: [
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          ),
        ),
        // More options button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: IconButton(
            onPressed: () => EventOptionsMenu.show(context, widget.eventId),
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
          ),
        ),
        // Main content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No photos yet',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to capture a moment!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              _buildPrimaryButton(
                onPressed: () => context.push('/camera/${widget.eventId}'),
                icon: Icons.camera_alt,
                label: 'Take Photo',
                width: 200,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(List<MediaItem> allMediaItems) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (_isHeaderCollapsed) ...[
            // Show event name when collapsed
            Expanded(
              child: Text(
                event?.name ?? 'Event Gallery',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
          _buildFilterTab('All', allMediaItems.length),
          const SizedBox(width: 8),
          _buildFilterTab(
            'Images',
            allMediaItems.where((item) => item.type == MediaType.image).length,
          ),
          const SizedBox(width: 8),
          _buildFilterTab(
            'Videos',
            allMediaItems.where((item) => item.type == MediaType.video).length,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, int count) {
    final theme = Theme.of(context);
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          '$filter ($count)',
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final theme = Theme.of(context);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddMediaOptions,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    double? width,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, color: theme.colorScheme.onPrimary, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  void _showAddMediaOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Media',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/camera/${widget.eventId}');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Media',
        extensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'JPG',
          'webp',
          'mp4',
          'mov',
          'avi',
          'webm'
        ],
      );
      
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);

      if (files.isEmpty || !mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading ${files.length} files...'),
            ],
          ),
        ),
      );

      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      final success = await mediaProvider.addMultipleMediaFromXFiles(
        eventId: widget.eventId,
        xFiles: files,
      );

      if (mounted) {
        // Ensure dialog is dismissed
        Navigator.of(context, rootNavigator: true).pop();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded ${files.length} files'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = mediaProvider.uploadError ?? 'Upload failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Ensure dialog is dismissed even on error
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  

  


  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 3;
    if (width < 900) return 4;
    return 5;
  }

  List<MediaItem> _filterMediaItems(List<MediaItem> items) {
    switch (_selectedFilter) {
      case 'Images':
        return items.where((item) => item.type == MediaType.image).toList();
      case 'Videos':
        return items.where((item) => item.type == MediaType.video).toList();
      default:
        return items;
    }
  }


}

// Custom Header Delegate for the collapsible header
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Event? event;
  final double maxHeight;
  final double minHeight;
  final String eventId;
  final bool isLoading;

  const _HeaderDelegate({
    required this.event,
    required this.maxHeight,
    required this.minHeight,
    required this.eventId,
    required this.isLoading,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    
    return EventHeader(
      event: event,
      eventId: eventId,
      isLoading: isLoading,
      progress: progress,
      onOptionsPressed: () => EventOptionsMenu.show(context, eventId),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}

// Enhanced Media Grid Item with better performance
class _MediaGridItem extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;

  const _MediaGridItem({
    required this.mediaItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Hero(
                tag: 'media-${mediaItem.id}',
                child: mediaItem.fileUrl != null && mediaItem.fileUrl!.startsWith('http')
                    ? Image.network(
                        mediaItem.fileUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingPlaceholder(theme);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildErrorPlaceholder(theme),
                      )
                    : mediaItem.fileUrl != null
                        ? Image.network(
                            mediaItem.fileUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildErrorPlaceholder(theme),
                          )
                        : _buildErrorPlaceholder(theme),
              ),
              
              // Video overlay
              if (mediaItem.type == MediaType.video)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: theme.colorScheme.primary,
          size: 32,
        ),
      ),
    );
  }
}

// Events Overview Screen - shows all events as cards
class EventsOverviewScreen extends StatelessWidget {
  const EventsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: ResponsiveLayout(
        child: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            final eventGroups = mediaProvider.getEventGroups();

            if (eventGroups.isEmpty) {
              return Center(
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
                        Icons.event_note_outlined,
                        size: 60,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No Events Yet',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Create your first event and start\ncapturing memories!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8E8E93),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 220,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.go('/create-event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Create Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Column(
                    children: [
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Your Events',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${eventGroups.length} events',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => context.go('/device-gallery'),
                            icon: const Icon(Icons.photo_library, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Events Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getGridColumns(context),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: eventGroups.length,
                      itemBuilder: (context, index) {
                        final eventId = eventGroups.keys.elementAt(index);
                        final mediaItems = eventGroups[eventId]!;
                        return _EventCard(
                          eventId: eventId,
                          mediaItems: mediaItems,
                          onTap: () => context.go('/gallery/$eventId'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.go('/create-event'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    return 3;
  }
}

class _EventCard extends StatelessWidget {
  final String eventId;
  final List<MediaItem> mediaItems;
  final VoidCallback onTap;

  const _EventCard({
    required this.eventId,
    required this.mediaItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final latestMedia = mediaItems.isNotEmpty 
        ? mediaItems.first 
        : null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image Preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: latestMedia != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background Image
                            latestMedia.fileUrl != null && latestMedia.fileUrl!.startsWith('http')
                                ? Image.network(
                                    latestMedia.fileUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  )
                                : latestMedia.fileUrl != null
                                    ? Image.network(
                                        latestMedia.fileUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholder();
                                        },
                                      )
                                    : _buildPlaceholder(),
                            
                            // Overlay Gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.4),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Media Count Badge
                            if (mediaItems.length > 1)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.collections,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${mediaItems.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),

            // Event Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEventDisplayName(eventId),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 16,
                          color: const Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${mediaItems.length} ${mediaItems.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const Spacer(),
                        if (latestMedia != null)
                          Text(
                            _formatDate(latestMedia.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C63FF).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF3A3A4E),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: 40,
              color: Color(0xFF6C63FF),
            ),
            SizedBox(height: 8),
            Text(
              'No media yet',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventDisplayName(String eventId) {
    if (eventId == 'device-gallery') return 'Device Gallery';
    // You can implement more sophisticated event name mapping here
    return 'Event ${eventId.substring(0, 8)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}