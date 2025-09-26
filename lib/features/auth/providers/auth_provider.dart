import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentEventId;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentEventId => _currentEventId;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      _currentEventId = prefs.getString('currentEventId');
    } catch (e) {
      debugPrint('Error loading auth state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinEventWithQR(String qrData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate QR code validation
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, you would validate the QR code with your backend
      if (qrData.isNotEmpty && qrData.startsWith('memora://event/')) {
        final eventId = qrData.split('/').last;
        _currentEventId = eventId;
        _isAuthenticated = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('currentEventId', eventId);
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error joining event: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _isAuthenticated = false;
      _currentEventId = null;
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}