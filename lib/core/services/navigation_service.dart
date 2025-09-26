import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static bool _isOnHomePage = true;
  static DateTime? _lastBackPressed;
  
  static void setCurrentPage(String route) {
    _isOnHomePage = route == '/';
  }
  
  static bool get isOnHomePage => _isOnHomePage;
  
  static bool handleBackNavigation(GoRouter router, GoRouterState state) {
  if (!_isOnHomePage) {
    router.go('/'); // ✅ correct
    return false;
  }

  final now = DateTime.now();
  if (_lastBackPressed == null ||
      now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
    _lastBackPressed = now;
    return false;
  }
  return true;
}
  
  static void exitApp() {
    SystemNavigator.pop();
  }
  
  static void navigateToHome(GoRouter router) {
    router.go('/');
    _isOnHomePage = true;
  }
}