import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../../media/providers/media_provider.dart';
import '../../../shared/models/event.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_provider.dart';

class EventsOverviewScreen extends StatefulWidget {
  const EventsOverviewScreen({super.key});

  @override
  State<EventsOverviewScreen> createState() => _EventsOverviewScreenState();
}

class _EventsOverviewScreenState extends State<EventsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final isLoggedIn = await AuthService.isLoggedIn();
    await eventProvider.loadEvents(requiresAuth: isLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
            backgroundColor: theme.colorScheme.surface,
      body: Consumer2<EventProvider, MediaProvider>(
        builder: (context, eventProvider, mediaProvider, child) {
                if (eventProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }

          final events = eventProvider.events;

          if (events.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: Row(
                  children: [
                          Text(
                      'Events',
                      style: TextStyle(
                              color: theme.colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                            onPressed: () => _refreshEvents(context),
                            icon: Icon(Icons.refresh,
                                color: theme.colorScheme.onSurface),
                          ),
                          IconButton(
                      onPressed: () => context.push('/device-gallery'),
                            icon: Icon(Icons.photo_library,
                                color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              
              // Events Grid
              Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _refreshEvents(context),
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getGridColumns(context),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              if (index < events.length) {
                                // Real events
                                final event = events[index];
                                final mediaItems =
                                    mediaProvider.getMediaForEvent(event.id);
                                return _EventCard(
                                  event: event,
                                  mediaCount: event.mediaCount > 0
                                      ? event.mediaCount
                                      : mediaItems.length,
                                  latestMedia: mediaItems.isNotEmpty
                                      ? mediaItems.first
                                      : null,
                                  onTap: () => context
                                      .push('/event/${event.id}/gallery'),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Join Event FAB
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () => context.push('/qr-scan'),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    heroTag: "join",
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Create Event FAB
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () => _handleCreateEvent(context),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    heroTag: "create",
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ));
      },
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first event and start\ncollecting memories together!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _handleCreateEvent(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      color: theme.colorScheme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
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

  Future<void> _handleCreateEvent(BuildContext context) async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      context.push('/create-event');
    } else {
      context.push('/welcome');
    }
  }


  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  Future<void> _refreshEvents(BuildContext context) async {
    await _loadEvents();
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final int mediaCount;
  final dynamic latestMedia;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.mediaCount,
    required this.latestMedia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PatternPainter(),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatEventDate(event.date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          
                          // Event Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Media Count Badge
                    if (mediaCount > 0)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_camera,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$mediaCount',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
                      event.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Status Indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getEventStatusColor(event.date, theme),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getEventStatus(event.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getEventStatusColor(event.date, theme),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 0) return 'In ${difference}d';
    if (difference == -1) return 'Yesterday';
    return '${-difference}d ago';
  }

  String _getEventStatus(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) return 'Upcoming';
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today';
    }
    return 'Past';
  }

  Color _getEventStatusColor(DateTime date, ThemeData theme) {
    final now = DateTime.now();
    if (date.isAfter(now)) return theme.colorScheme.primary;
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return Colors.green;
    }
    return theme.colorScheme.onSurface.withOpacity(0.7);
  }
}



class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        canvas.drawCircle(
          Offset(i * 20.0 + 10, j * 20.0 + 10),
          2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}