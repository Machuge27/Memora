import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.verifyEmail(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          if (result['already_verified'] == true) {
            _showSuccess(result['message'] ?? 'Email already verified');
            context.go('/sign-in');
          } else if (result['data']?['access'] != null) {
            context.read<AuthProvider>().setAuthenticated(true);
            _showSuccess(result['message'] ?? 'Email verified successfully!');
            context.go('/events');
          } else {
            _showSuccess(result['message'] ?? 'Email verified successfully!');
            context.go('/sign-in');
          }
        } else {
          final errors = result['errors'];
          if (errors != null && errors is Map) {
            final errorMessages = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.cast<String>());
              }
            });
            _showError(errorMessages.isNotEmpty ? errorMessages.join(', ') : result['message'] ?? 'Verification failed');
          } else {
            _showError(result['message'] ?? 'Verification failed');
          }
        }
      }
    } catch (e) {
      if (mounted) _showError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      await AuthService.sendOTP(email: widget.email, purpose: 'email_verify');
      if (mounted) _showSuccess('Verification code sent!');
    } catch (e) {
      if (mounted) _showError('Failed to resend code');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
                  Text('Verify Email', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Enter the code sent to ${widget.email}', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    validator: (value) => value?.isEmpty == true ? 'Verification code is required' : null,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: Text(
                      _isResending ? 'Resending...' : 'Resend Code',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                          : Text('Verify', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
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