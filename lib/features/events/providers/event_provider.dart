import 'package:flutter/foundation.dart';
import '../../../shared/models/event.dart';
import '../../../core/services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final List<Event> _events = [];
  Event? _currentEvent;
  bool _isLoading = false;

  List<Event> get events => List.unmodifiable(_events);
  Event? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;

  EventProvider();

  final Map<String, Event> _eventCache = {};

  Future<Event?> getEventById(String eventId) async {
    // Return cached event if available
    if (_eventCache.containsKey(eventId)) {
      _currentEvent = _eventCache[eventId];
      return _currentEvent;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await EventService.getEvent(eventId);
      final event = Event.fromJson(response);
      _currentEvent = event;
      _eventCache[eventId] = event; // Cache the event
      return event;
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Event?> createEvent({
    required String name,
    required String description,
    required DateTime date,
    required String location,
    String privacy = 'public',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await EventService.createEvent(
        name: name,
        description: description,
        date: date.toIso8601String(),
        location: location,
        privacy: privacy,
      );
      final event = Event.fromJson(response);
      _events.add(event);
      return event;
    } catch (e) {
      debugPrint('Error creating event: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEvents({bool requiresAuth = true}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await EventService.getEvents(requiresAuth: requiresAuth);
      final eventsList = response['results'] as List;
      _events.clear();
      _events.addAll(eventsList.map((json) => Event.fromJson(json)));
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> joinEvent(String eventId) async {
    try {
      final response = await EventService.joinEvent(eventId);
      await loadEvents(); // Refresh events after joining
      return response;
    } catch (e) {
      debugPrint('Error joining event: $e');
      return null;
    }
  }

  Future<bool> leaveEvent(String eventId) async {
    try {
      await EventService.leaveEvent(eventId);
      await loadEvents(); // Refresh events after leaving
      return true;
    } catch (e) {
      debugPrint('Error leaving event: $e');
      return false;
    }
  }

  Future<Event?> updateEvent({
    required String eventId,
    String? name,
    String? description,
    DateTime? date,
    String? location,
    String? privacy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await EventService.updateEvent(
        eventId,
        name: name,
        description: description,
        date: date?.toIso8601String(),
        location: location,
        privacy: privacy,
      );
      final updatedEvent = Event.fromJson(response);
      
      // Update in local list
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        _events[index] = updatedEvent;
      }
      
      // Update cache and current event
      _eventCache[eventId] = updatedEvent;
      if (_currentEvent?.id == eventId) {
        _currentEvent = updatedEvent;
      }
      
      return updatedEvent;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await EventService.deleteEvent(eventId);
      if (response['success'] == true) {
        // Remove from local list
        _events.removeWhere((e) => e.id == eventId);
        
        // Remove from cache
        _eventCache.remove(eventId);
        
        // Clear current event if it's the deleted one
        if (_currentEvent?.id == eventId) {
          _currentEvent = null;
        }
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Event>> getMyEvents() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await EventService.getMyEvents();
      final eventsList = response['results'] as List;
      return eventsList.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading my events: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Event>> getCreatedEvents() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await EventService.getCreatedEvents();
      final eventsList = response['results'] as List;
      return eventsList.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading created events: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> joinEventWithQR(String qrData) async {
    try {
      // Extract event ID from QR data
      String? eventId;
      if (qrData.startsWith('memora://event/')) {
        eventId = qrData.replaceFirst('memora://event/', '');
      } else {
        // Try to parse as direct event ID
        eventId = qrData;
      }
      
      if (eventId != null && eventId.isNotEmpty) {
        final response = await EventService.joinEvent(eventId);
        await loadEvents(); // Refresh events after joining
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error joining event with QR: $e');
      return null;
    }
  }

  void addMediaToEvent(String eventId, String mediaId) {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex != -1) {
      _events[eventIndex] = _events[eventIndex].copyWith(
        mediaCount: _events[eventIndex].mediaCount + 1,
      );
      
      if (_currentEvent?.id == eventId) {
        _currentEvent = _events[eventIndex];
      }
      
      notifyListeners();
    }
  }
}