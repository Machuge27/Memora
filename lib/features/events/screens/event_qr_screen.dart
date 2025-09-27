import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../../../shared/models/event.dart';
import '../../../core/theme/theme_provider.dart';

class EventQRScreen extends StatefulWidget {
  final String eventId;

  const EventQRScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventQRScreen> createState() => _EventQRScreenState();
}

class _EventQRScreenState extends State<EventQRScreen> {
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Event QR Code',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              if (event != null)
                IconButton(
                  onPressed: _shareQRCode,
                  icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
                ),
            ],
          ),
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                )
              : event == null
                  ? Center(
                      child: Text(
                        'Event not found',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    )
                  : _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Share Event QR Code',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Others can scan this code to join "${event!.name}"',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                if (event!.qrCodeUrl != null)
                  Image.network(
                    event!.qrCodeUrl!,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 220,
                        height: 220,
                        color: Colors.grey[300],
                        child: const Icon(Icons.qr_code, size: 100),
                      );
                    },
                  )
                else
                  Container(
                    width: 220,
                    height: 220,
                    color: Colors.grey[300],
                    child: const Icon(Icons.qr_code, size: 100),
                  ),
                const SizedBox(height: 20),
                Text(
                  event!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  event!.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
        SnackBar(
          content: const Text('QR code URL copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}