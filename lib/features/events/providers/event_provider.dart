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

  Future<Event?> getEventById(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await EventService.getEvent(eventId);
      final event = Event.fromJson(response);
      _currentEvent = event;
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
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await EventService.createEvent(
        name: name,
        description: description,
        date: date.toIso8601String(),
        location: location,
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

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await EventService.getEvents();
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