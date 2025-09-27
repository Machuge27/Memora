import 'dart:async';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'auth_service.dart';

class TokenManager {
  static Timer? _refreshTimer;
  static bool _isRefreshing = false;

  static Future<void> startTokenRefreshTimer() async {
    await _scheduleNextRefresh();
  }

  static void stopTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  static Future<void> _scheduleNextRefresh() async {
    _refreshTimer?.cancel();
    
    final token = await AuthService.getStoredToken();
    if (token == null) return;

    try {
      // Check if token is expired or will expire soon
      final isExpired = JwtDecoder.isExpired(token);
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      
      // Refresh if token expires within 5 minutes
      final shouldRefresh = isExpired || expirationDate.difference(now).inMinutes <= 5;
      
      if (shouldRefresh) {
        await _refreshTokenIfNeeded();
      } else {
        // Schedule refresh 5 minutes before expiration
        final refreshTime = expirationDate.subtract(const Duration(minutes: 5));
        final delay = refreshTime.difference(now);
        
        if (delay.isNegative) {
          await _refreshTokenIfNeeded();
        } else {
          _refreshTimer = Timer(delay, () => _refreshTokenIfNeeded());
        }
      }
    } catch (e) {
      // If token is invalid, try to refresh
      await _refreshTokenIfNeeded();
    }
  }

  static Future<void> _refreshTokenIfNeeded() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    
    try {
      await AuthService.refreshToken();
      await _scheduleNextRefresh(); // Schedule next refresh
    } catch (e) {
      // If refresh fails, user needs to login again
      await AuthService.logout();
    } finally {
      _isRefreshing = false;
    }
  }

  static Future<bool> isTokenValid() async {
    final token = await AuthService.getStoredToken();
    if (token == null) return false;
    
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }
}