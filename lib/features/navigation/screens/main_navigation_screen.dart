import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/navigation_service.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../events/screens/events_overview_screen.dart';
import '../../auth/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget? child;
  final int initialIndex;
  
  const MainNavigationScreen({
    super.key,
    this.child,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    NavigationService.setCurrentPage('/');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.toString();
    setState(() {
      if (location.startsWith('/events') || location.startsWith('/gallery')) {
        _currentIndex = 0;
      } else if (location.startsWith('/friends')) {
        _currentIndex = 1;
      } else if (location.startsWith('/welcome') || location.startsWith('/sign-in') || location.startsWith('/sign-up') || location == '/') {
        _currentIndex = 2;
      } else if (location.startsWith('/qr-scan')) {
        _currentIndex = 3;
      } else if (location.startsWith('/profile')) {
        _currentIndex = 4;
      } else {
        _currentIndex = 0;
      }
    });
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/events');
        break;
      case 1:
        context.go('/friends');
        break;
      case 2:
        context.go('/');
        break;
      case 3:
        context.go('/qr-scan');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  bool _onWillPop() {
    if (_currentIndex != 0) {
      context.go('/');
      return false;
    }
    
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Press back again to exit'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _onWillPop()) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child ?? const WelcomeScreen(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Events',
                    index: 0,
                    isSelected: _currentIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.people_rounded,
                    label: 'Friends',
                    index: 1,
                    isSelected: _currentIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Icons.add_circle_sharp,
                    label: 'Create',
                    index: 2,
                    isSelected: _currentIndex == 2,
                  ),
                  _buildNavItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan',
                    index: 3,
                    isSelected: _currentIndex == 3,
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    isSelected: _currentIndex == 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () => _onTabTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$isSelected'),
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ) ?? const TextStyle(),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}