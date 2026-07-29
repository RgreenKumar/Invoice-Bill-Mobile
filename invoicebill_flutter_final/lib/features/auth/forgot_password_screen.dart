import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../theme/app_theme.dart';

/// Port of `src/AuthenticationPages/forgetpassword.js`.
///
/// Two-step flow, exactly as the original:
///   Step 1: POST /forgetpassword (FormData: email) -> on 200, reveal step 2
///   Step 2: POST /resetpassword (FormData: email, password) -> on 200,
///           success dialog then navigate to /login; on 404, "User not found"
///
/// Client-side validation preserved: email regex
/// `^[^\s@]+@[^\s@]+\.[^\s@]+$`, password regex requiring 8+ chars with
/// upper/lower/digit/special char, confirm-password match, and (on the
/// reset submit handler specifically) a redundant >=6-char length check -
/// all kept exactly as in the source even though the regex already
/// enforces a stricter 8-char minimum.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isResetPassword = false;
  String _email = '';

  final _forgetEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _submitting = false;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  bool get _isForgetButtonDisabled => _forgetEmailController.text.isEmpty || _emailError != null;

  bool get _isResetButtonDisabled =>
      _email.isEmpty ||
      _emailError != null ||
      _passwordController.text.isEmpty ||
      _confirmPasswordController.text.isEmpty ||
      _passwordError != null ||
      _confirmPasswordError != null;

  void _onEmailChanged(String value) {
    setState(() => _emailError = _emailRegex.hasMatch(value) ? null : 'Please enter a valid email address');
  }

  void _onPasswordChanged(String value) {
    setState(() =>
        _passwordError = _passwordRegex.hasMatch(value)
            ? null
            : 'Password must be at least 8 characters, include uppercase, lowercase, digit, and special character.');
  }

  void _onConfirmPasswordChanged(String value) {
    setState(() =>
        _confirmPasswordError = value != _passwordController.text ? 'Passwords do not match' : null);
  }

  Future<void> _handleForgetPasswordSubmit() async {
    try {
      final formData = FormData.fromMap({'email': _forgetEmailController.text});
      final res = await ApiClient.instance.dio.post('/forgetpassword', data: formData);
      if (res.statusCode == 200) {
        setState(() {
          _email = _forgetEmailController.text;
          _isResetPassword = true;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(() => _emailError = 'User not found');
      } else if (mounted) {
        // Was `rethrow` (uncaught) - surface connection/CORS/server errors
        // instead of failing silently.
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Connection Error'),
            content: Text('Could not reach the server (${e.type.name}). '
                'Check that the backend is running and reachable, and that '
                'it allows requests from this app\'s origin (CORS) if '
                'running on web.\n\n${e.message ?? ''}'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
      }
    }
  }

  Future<void> _handleResetPasswordSubmit() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters long');
      return;
    }
    setState(() => _submitting = true);
    try {
      final formData = FormData.fromMap({'email': _email, 'password': _passwordController.text});
      final res = await ApiClient.instance.dio.post('/resetpassword', data: formData);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Your password has been reset successfully!'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) context.go('/login');
      } else if (res.statusCode == 404) {
        setState(() => _emailError = 'User not found');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _forgetEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long, size: 40, color: AppColors.darkMid),
                  const SizedBox(height: 16),
                  Text(_isResetPassword ? 'Change Password' : 'User Verification', style: AppTheme.headingSerif),
                  const SizedBox(height: 24),
                  if (!_isResetPassword) ..._verificationStep() else ..._resetStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _verificationStep() {
    return [
      TextField(
        controller: _forgetEmailController,
        autofocus: true,
        onChanged: _onEmailChanged,
        decoration: InputDecoration(hintText: 'Enter Email Address', errorText: _emailError),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _isForgetButtonDisabled ? null : _handleForgetPasswordSubmit,
          child: const Text('Verify'),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: () => context.go('/login'), child: const Text('Back to Login')),
      const Divider(height: 32),
      TextButton(onPressed: () => context.go('/login'), child: const Text('Go to Login page!')),
    ];
  }

  List<Widget> _resetStep() {
    return [
      TextField(
        controller: TextEditingController(text: _email),
        readOnly: true,
        decoration: const InputDecoration(filled: true, fillColor: Color(0xFFF0F4F8)),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordController,
        obscureText: true,
        onChanged: _onPasswordChanged,
        decoration: InputDecoration(hintText: 'New Password', errorText: _passwordError),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _confirmPasswordController,
        obscureText: true,
        onChanged: _onConfirmPasswordChanged,
        decoration: InputDecoration(hintText: 'Confirm Password', errorText: _confirmPasswordError),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: (_isResetButtonDisabled || _submitting) ? null : _handleResetPasswordSubmit,
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Reset Password'),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: () => context.go('/login'), child: const Text('Cancel')),
    ];
  }
}
