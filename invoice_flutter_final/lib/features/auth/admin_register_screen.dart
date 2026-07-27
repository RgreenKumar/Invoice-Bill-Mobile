import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/safe_back.dart';
import '../../core/api/api_client.dart';
import '../../theme/app_theme.dart';

/// Port of `src/Registration/AdminRegister.js`.
///
/// This is the screen that actually creates a new Admin/Institute account
/// (each registrant becomes their own tenant's Admin) - reached via
/// `/RegisterInstitute` (SAS-mode landing page) or `/adminRegistration`
/// (shown from the login screen's "New user?" link when no admin exists
/// yet in VPS mode).
///
/// Preserves:
///  - POST /auth/send-otp + /auth/verify-otp email verification gate,
///    identical flow/copy to AddCustomer.js's OTP handling
///  - POST /admin/register as multipart FormData with fields: username,
///    psw, email, institutionName, dob, role ("ADMIN"), phone, isActive,
///    profile (image file), gstinNumber, countryCode, otp
///  - Required fields: institution, email, psw, confirm_password, phone
///    (username/dob/gstinNumber are NOT required, matching the source)
///  - Validation: email `^[^\s@]+@[^\s@]+\.com$`, password needs 8+ chars
///    with upper/lower/digit/special char, confirm must match, DOB between
///    8 and 100 years old if provided, profile image capped at 50KB
///  - 400 "EMAIL" -> email already registered; 400 "INSTITUTE" -> institution
///    already registered; 400 "ADMIN" -> "Admin Already Registered" dialog
///  - On success: dialog with "Go to Login" (navigates to /login) or
///    "Cancel" (resets the form to try again)
///
/// NOT ported 1:1: the original auto-detected the visitor's country/
/// dialing code via `https://ipapi.co/json/` and
/// `https://restcountries.com/...` and used `react-phone-number-input`
/// for international phone formatting. This version uses a plain phone
/// field (India-oriented placeholder) instead - add a package like
/// `intl_phone_field` if exact international-dialing-code parity matters.
class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isSendingOtp = false;
  bool _submitting = false;
  String _otp = '';

  final _formData = <String, String>{
    'username': '', 'psw': '', 'confirm_password': '', 'email': '',
    'institution': '', 'dob': '', 'phone': '', 'gstinNumber': '',
    'countryCode': '+91',
  };

  final _errors = <String, String?>{
    'username': null, 'email': null, 'institution': null, 'dob': null,
    'psw': null, 'gstinNumber': null, 'confirm_password': null,
    'phone': null, 'profile': null, 'otp': null,
  };

  PlatformFile? _profileFile;
  Uint8List? _profileBytes;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.com$');
  static final _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  void _handleChange(String name, String value) {
    String? error;
    switch (name) {
      case 'email':
        error = _emailRegex.hasMatch(value) ? null : 'Please enter a valid email address';
        break;
      case 'institution':
        error = value.isEmpty ? 'Please enter a Institution Name' : null;
        break;
      case 'dob':
        if (value.isNotEmpty) {
          final dob = DateTime.tryParse(value);
          if (dob != null) {
            final now = DateTime.now();
            final maxDate = DateTime(now.year - 8, now.month, now.day);
            final minDate = DateTime(now.year - 100, now.month, now.day);
            error = (dob.isBefore(maxDate.add(const Duration(days: 1))) && dob.isAfter(minDate))
                ? null : 'Please enter a valid date of birth';
          }
        }
        break;
      case 'psw':
        error = _passwordRegex.hasMatch(value)
            ? null
            : 'Password must be at least 8 characters long, include at least one uppercase letter, one lowercase letter, one digit, and one special character.';
        if (error == null && _formData['confirm_password']!.isNotEmpty && _formData['confirm_password'] != value) {
          _errors['confirm_password'] = 'Confirm password does not match the password.';
        }
        break;
      case 'confirm_password':
        error = value != _formData['psw'] ? 'Passwords do not match' : null;
        break;
    }
    setState(() {
      _errors[name] = error;
      _formData[name] = value;
    });
  }

  void _handlePhoneChange(String value) {
    setState(() {
      _formData['phone'] = value;
      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
      _errors['phone'] = digitsOnly.length >= 7 ? null : 'Enter a valid Phone number';
    });
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 50 * 1024) {
      setState(() => _errors['profile'] = 'Image size must be 50 KB or smaller');
      return;
    }
    setState(() {
      _errors['profile'] = null;
      _profileFile = file;
      _profileBytes = file.bytes;
    });
  }

  Future<void> _handleSendOtp() async {
    if (_formData['email']!.isEmpty || _errors['email'] != null) {
      setState(() => _errors['email'] = _formData['email']!.isEmpty ? 'Email is required' : _errors['email']);
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      setState(() {
        _otp = '';
        _errors['otp'] = null;
        _otpVerified = false;
        _otpSent = true;
      });
      final res = await ApiClient.instance.dio
          .post('/auth/send-otp', queryParameters: {'email': _formData['email']});
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('OTP Sent! Please check your email.')));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data == 'EMAIL') {
        setState(() => _errors['email'] = 'This email is already registered');
      } else {
        setState(() => _errors['email'] = 'Failed to send OTP. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otp.isEmpty) {
      setState(() => _errors['otp'] = 'OTP is required');
      return;
    }
    try {
      final res = await ApiClient.instance.dio
          .post('/auth/verify-otp', queryParameters: {'email': _formData['email'], 'otp': _otp});
      if (res.statusCode == 200) {
        setState(() {
          _otpVerified = true;
          _errors['otp'] = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Email verified successfully!')));
        }
      }
    } catch (_) {
      setState(() => _errors['otp'] = 'Invalid or expired OTP');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_otpVerified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please Verify Your Email First!')));
      return;
    }

    final requiredFields = ['institution', 'email', 'psw', 'confirm_password', 'phone'];
    var hasErrors = false;
    for (final field in requiredFields) {
      if (_formData[field]!.isEmpty || _errors[field] != null) {
        hasErrors = true;
        setState(() => _errors[field] = _formData[field]!.isEmpty ? 'This field is required' : _errors[field]);
      }
    }
    if (hasErrors) return;

    setState(() => _submitting = true);
    try {
      final formData = FormData.fromMap({
        'username': _formData['username'],
        'psw': _formData['psw'],
        'email': _formData['email'],
        'institutionName': _formData['institution'],
        'dob': _formData['dob'],
        'role': 'ADMIN',
        'phone': _formData['phone'],
        'isActive': 'true',
        if (_profileFile?.bytes != null)
          'profile': MultipartFile.fromBytes(_profileFile!.bytes!, filename: _profileFile!.name),
        'gstinNumber': _formData['gstinNumber'],
        'countryCode': _formData['countryCode'],
        'otp': _otp,
      });

      final res = await ApiClient.instance.dio.post('/admin/register', data: formData);
      if (res.statusCode == 200 && mounted) {
        final goToLogin = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Welcome to our Family!'),
            content: const Text('You have been registered successfully!'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Go to Login')),
            ],
          ),
        );
        if (goToLogin == true) {
          if (mounted) context.go('/login');
        } else {
          _resetForm();
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data == 'EMAIL') {
          setState(() => _errors['email'] = 'This email is already registered.');
        } else if (data == 'INSTITUTE') {
          setState(() => _errors['institution'] = 'This institution is already registered.');
        } else if (data == 'ADMIN' && mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error!'),
              content: const Text('Admin Already Registered.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ),
          );
        }
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Connection Error'),
            content: Text('Could not reach the server (${e.type.name}).\n\n${e.message ?? ''}'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _formData.updateAll((key, value) => key == 'countryCode' ? '+91' : '');
      _errors.updateAll((key, value) => null);
      _profileFile = null;
      _profileBytes = null;
      _otpSent = false;
      _otpVerified = false;
      _otp = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkStart,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Join with us', style: AppTheme.headingSerif),
                      const SizedBox(height: 16),
                      _profilePicker(),
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(labelText: 'Name', errorText: _errors['username']),
                        onChanged: (v) => _handleChange('username', v),
                      ),
                      const SizedBox(height: 12),
                      _emailWithOtp(),
                      if (_otpSent && !_otpVerified) ...[
                        const SizedBox(height: 12),
                        _otpField(),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(labelText: 'Institution Name *', errorText: _errors['institution']),
                        onChanged: (v) => _handleChange('institution', v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          errorText: _errors['psw'],
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        onChanged: (v) => _handleChange('psw', v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: !_showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Re-type password *',
                          errorText: _errors['confirm_password'],
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                          ),
                        ),
                        onChanged: (v) => _handleChange('confirm_password', v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Phone *',
                          errorText: _errors['phone'],
                          prefixText: '${_formData['countryCode']} ',
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: _handlePhoneChange,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Date of Birth'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(DateTime.now().year - 25),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) _handleChange('dob', date.toIso8601String().split('T').first);
                        },
                        controller: TextEditingController(text: _formData['dob']),
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(labelText: 'gstinNumber', errorText: _errors['gstinNumber']),
                        onChanged: (v) => _handleChange('gstinNumber', v),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              OutlinedButton(onPressed: () => safeBack(context, fallback: '/login'), child: const Text('Cancel')),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _submitting ? null : _handleSubmit,
                                child: _submitting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Register'),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Already have an account? Login!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profilePicker() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF0F4F8),
            backgroundImage: _profileBytes != null ? MemoryImage(_profileBytes!) : null,
            child: _profileBytes == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _pickProfileImage, child: const Text('Upload')),
          if (_errors['profile'] != null)
            Text(_errors['profile']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _emailWithOtp() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(labelText: 'Email *', errorText: _errors['email']),
            enabled: !_otpVerified,
            onChanged: (v) => _handleChange('email', v),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _otpVerified
              ? const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 4),
                    Text('Verified'),
                  ]),
                )
              : OutlinedButton(
                  onPressed: (_formData['email']!.isEmpty || _errors['email'] != null || _isSendingOtp)
                      ? null : _handleSendOtp,
                  child: Text(_isSendingOtp ? 'Sending...' : (_otpSent ? 'Resend OTP' : 'Send OTP')),
                ),
        ),
      ],
    );
  }

  Widget _otpField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(hintText: 'Enter 6-digit OTP', errorText: _errors['otp']),
            maxLength: 6,
            onChanged: (v) => setState(() => _otp = v.replaceAll(RegExp(r'\D'), '')),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _otp.length == 6 ? _handleVerifyOtp : null,
          child: const Text('Verify OTP'),
        ),
      ],
    );
  }
}
