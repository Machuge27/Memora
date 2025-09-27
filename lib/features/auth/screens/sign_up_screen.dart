import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
      );

      if (mounted) {
        if (result['message']?.contains('Registration successful') == true) {
          context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
        } else {
          final errors = <String>[];
          result.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.cast<String>());
            }
          });
          _showError(errors.isNotEmpty ? errors.join(', ') : 'Sign up failed');
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      validator: (value) => value?.isEmpty == true ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Email is required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Password is required';
                        if (value!.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                            : Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/sign-in'),
                      child: Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
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