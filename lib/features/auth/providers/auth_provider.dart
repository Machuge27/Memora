import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/token_manager.dart';

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
      _isAuthenticated = await AuthService.isLoggedIn() && await TokenManager.isTokenValid();
      if (_isAuthenticated) {
        await TokenManager.startTokenRefreshTimer();
      }
      
      final prefs = await SharedPreferences.getInstance();
      _currentEventId = prefs.getString('currentEventId');
    } catch (e) {
      debugPrint('Error loading auth state: $e');
      _isAuthenticated = false;
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
      await AuthService.logout();
      TokenManager.stopTokenRefreshTimer();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentEventId');
      
      _isAuthenticated = false;
      _currentEventId = null;
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (authenticated) {
      TokenManager.startTokenRefreshTimer();
    } else {
      TokenManager.stopTokenRefreshTimer();
    }
    notifyListeners();
  }
}