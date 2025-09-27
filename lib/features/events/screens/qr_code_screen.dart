import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/event_provider.dart';
import '../../../shared/models/event.dart';

class QRCodeScreen extends StatefulWidget {
  final String eventId;

  const QRCodeScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
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
          'Event QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (event?.qrCodeUrl != null)
            IconButton(
              onPressed: _shareQRCode,
              icon: const Icon(Icons.share, color: Colors.white),
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
                    children: [
                      _buildEventHeader(),
                      const SizedBox(height: 32),
                      _buildQRCodeSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            event!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(event!.date),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event!.location,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (event!.qrCodeUrl != null)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  event!.qrCodeUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return QrImageView(
                      data: 'memora://event/${event!.id}',
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    );
                  },
                ),
              ),
            )
          else
            QrImageView(
              data: 'memora://event/${event!.id}',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: _shareQRCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Share QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareQRCode() {
    if (event?.qrCodeUrl != null) {
      Clipboard.setData(ClipboardData(text: event!.qrCodeUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code URL copied to clipboard'),
          backgroundColor: Color(0xFF6C63FF),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}