import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() => _isLoading = false);
        return;
      }
      
      final profile = await AuthService.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.logout();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        
        if (_isLoading) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
          );
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: _profile != null ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Profile',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            actions: [
              IconButton(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ) : null,
          body: _profile != null
              ? _buildProfileContent()
              : _buildSignInPrompt(),
        );
      },
    );
  }

  Widget _buildProfileContent() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.colorScheme.background],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${_profile!['username'] ?? 'User'}!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (_profile!['email'] != null)
              Text(
                _profile!['email'],
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _handleSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.colorScheme.background],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.person_outline,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Sign In Required',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in to view your profile\nand access all features',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/welcome'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, color: theme.colorScheme.onPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}