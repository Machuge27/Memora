import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/event.dart';
import '../providers/event_provider.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Event? event;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final loadedEvent = await eventProvider.getEventById(widget.eventId);
    if (mounted) {
      setState(() {
        event = loadedEvent;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/event/${widget.eventId}/qr'),
            icon: const Icon(Icons.qr_code, color: Colors.white),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : event == null
              ? const Center(
                  child: Text(
                    'Event not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventHeader(),
                      const SizedBox(height: 32),
                      _buildEventInfo(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (event!.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_month, 'Date', _formatDate(event!.date)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, 'Location', event!.location),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.people, 'Participants', '${event!.participantsCount}'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.photo_library, 'Media', '${event!.mediaCount}'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.visibility, 'Privacy', event!.privacy.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.photo_library,
          label: 'View Gallery',
          onPressed: () => context.push('/gallery/${widget.eventId}'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.camera_alt,
          label: 'Take Photo',
          onPressed: () => context.push('/camera/${widget.eventId}'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.qr_code,
          label: 'Show QR Code',
          onPressed: () => context.push('/event/${widget.eventId}/qr'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, color: const Color(0xFF6C63FF)),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}