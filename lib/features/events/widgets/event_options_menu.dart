import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/event_provider.dart';
import '../../../shared/models/event.dart';

class EventOptionsMenu {
  static void show(BuildContext context, String eventId) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EventOptionsSheet(eventId: eventId),
    );
  }
}

class _EventOptionsSheet extends StatelessWidget {
  final String eventId;

  const _EventOptionsSheet({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final event = eventProvider.currentEvent;

    return Container(
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
            'Event Options',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildOption(
            context,
            icon: Icons.edit,
            title: 'Edit Event',
            subtitle: 'Update event details',
            onTap: () {
              Navigator.pop(context);
              _showEditEventDialog(context, event);
            },
          ),
          
          _buildOption(
            context,
            icon: Icons.people,
            title: 'View Participants',
            subtitle: 'See who joined this event',
            onTap: () {
              Navigator.pop(context);
              _showParticipants(context, eventId);
            },
          ),
          
          _buildOption(
            context,
            icon: Icons.qr_code,
            title: 'Share QR Code',
            subtitle: 'Let others join via QR',
            onTap: () {
              Navigator.pop(context);
              _showQRCode(context, event);
            },
          ),
          
          _buildOption(
            context,
            icon: Icons.delete,
            title: 'Delete Event',
            subtitle: 'Permanently remove this event',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, eventId);
            },
            isDestructive: true,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: color.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event? event) {
    if (event == null) return;
    
    final nameController = TextEditingController(text: event.name);
    final descriptionController = TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    DateTime selectedDate = event.date;
    String selectedPrivacy = event.privacy ?? 'public';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time'),
                  subtitle: Text(selectedDate.toString().split('.')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPrivacy,
                  decoration: const InputDecoration(
                    labelText: 'Privacy',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPrivacy = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                final updatedEvent = await eventProvider.updateEvent(
                  eventId: event.id,
                  name: nameController.text,
                  description: descriptionController.text,
                  location: locationController.text,
                  date: selectedDate,
                  privacy: selectedPrivacy,
                );
                
                if (updatedEvent != null && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update event'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final eventProvider = Provider.of<EventProvider>(context, listen: false);
              final success = await eventProvider.deleteEvent(eventId);
              
              if (success && context.mounted) {
                Navigator.pop(context); // Close dialog
                context.go('/events'); // Navigate to events overview
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete event'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showParticipants(BuildContext context, String eventId) {
    // TODO: Implement participants view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Participants view coming soon')),
    );
  }

  void _showQRCode(BuildContext context, Event? event) {
    if (event?.qrCodeUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${event!.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.network(
                event.qrCodeUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.qr_code,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Share this QR code for others to join'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}