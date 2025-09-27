import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result['access'] != null && result['user'] != null) {
          context.read<AuthProvider>().setAuthenticated(true);
          context.go('/events');
        } else if (result['requires_verification'] == true) {
          context.go('/verify-email?email=${Uri.encodeComponent(result['email'] ?? '')}');
        } else {
          _showError(result['message'] ?? 'Sign in failed');
        }
      }
    } catch (e) {
      if (mounted) _showError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Email Verification Required', style: TextStyle(color: Colors.white)),
        content: Text('Please verify your email to continue.', style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.colorScheme.surface, theme.colorScheme.background],
              ),
            ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Sign in to continue', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    validator: (value) => value?.isEmpty == true ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    validator: (value) => value?.isEmpty == true ? 'Password is required' : null,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                          : Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/sign-up'),
                      child: Text("Don't have an account? Sign Up", style: TextStyle(color: theme.colorScheme.primary, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
          ),
        );
      },
    );
  }
}