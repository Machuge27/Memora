import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/event.dart';

class EventHeader extends StatelessWidget {
  final Event? event;
  final String eventId;
  final bool isLoading;
  final double progress;
  final VoidCallback onOptionsPressed;

  const EventHeader({
    super.key,
    required this.event,
    required this.eventId,
    required this.isLoading,
    required this.progress,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: onOptionsPressed,
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ),
            Opacity(
              opacity: 1.0 - (progress * 0.3),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event != null && !isLoading) ...[
                      Text(
                        event!.name,
                        style: TextStyle(
                          fontSize: 28 - (progress * 8),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16 - (progress * 8)),
                      if (progress < 0.7) ...[
                        _buildEventInfo(Icons.calendar_month, _formatDate(event!.date)),
                        const SizedBox(height: 8),
                        _buildEventInfo(Icons.location_on, event!.location),
                        if (event!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildEventInfo(Icons.description, event!.description),
                        ],
                      ],
                      const Spacer(),
                      if (progress < 0.5)
                        Row(
                          children: [
                            Expanded(
                              child: _buildHeaderButton(
                                context,
                                icon: Icons.camera_alt,
                                label: 'Camera',
                                onPressed: () => context.push('/camera/$eventId'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildHeaderButton(
                                context,
                                icon: Icons.qr_code,
                                label: 'QR Code',
                                onPressed: () => context.push('/event/$eventId/qr'),
                              ),
                            ),
                          ],
                        ),
                    ] else ...[
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}