import 'dart:convert';
import 'api_service.dart';

class EventService {
  static Future<Map<String, dynamic>> getEvents({bool requiresAuth = true}) async {
    final response = await ApiService.get('/events/', requiresAuth: requiresAuth);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getEvent(String eventId, {bool requiresAuth = true}) async {
    final response = await ApiService.get('/events/$eventId/', requiresAuth: requiresAuth);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createEvent({
    required String name,
    required String description,
    required String date,
    required String location,
    String privacy = 'public',
  }) async {
    final response = await ApiService.post('/events/', body: {
      'name': name,
      'description': description,
      'date': date,
      'location': location,
      'privacy': privacy,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateEvent(
    String eventId, {
    String? name,
    String? description,
    String? date,
    String? location,
    String? privacy,
  }) async {
    final response = await ApiService.patch('/events/$eventId/', body: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (location != null) 'location': location,
      if (privacy != null) 'privacy': privacy,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    final response = await ApiService.delete('/events/$eventId/');
    return response.statusCode == 204 ? {'success': true} : jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> joinEvent(String eventId) async {
    final response = await ApiService.post('/events/join/', body: {
      'event_id': eventId,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> leaveEvent(String eventId) async {
    final response = await ApiService.post('/events/$eventId/leave/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMyEvents() async {
    final response = await ApiService.get('/events/my-events/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCreatedEvents() async {
    final response = await ApiService.get('/events/created-events/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getEventParticipants(String eventId) async {
    final response = await ApiService.get('/events/$eventId/participants/');
    return jsonDecode(response.body);
  }

  // Friendship methods
  static Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    final response = await ApiService.post('/events/friends/send-request/', body: {
      'user_id': userId,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> respondToFriendRequest(
    int friendshipId,
    String action,
  ) async {
    final response = await ApiService.post('/events/friends/respond/$friendshipId/', body: {
      'action': action,
    });

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFriends() async {
    final response = await ApiService.get('/events/friends/');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPendingRequests() async {
    final response = await ApiService.get('/events/friends/pending/');
    return jsonDecode(response.body);
  }
}