import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session_manager.dart';
import '../../core/utils/safe_back.dart';

/// Port of `src/Common Components/ProfileView.js`, routed at
/// `/course/dashboard/profile`.
///
/// Preserves:
///  - GET /student/users/{email} on load, re-fetched whenever `isEditing`
///    toggles (matches the original's `[email, isEditing]` dependency)
///  - 401 -> navigate to /unauthorized
///  - PATCH /Edit/self as multipart form data: username, email, dob
///    (blanked if null), phone, profile (image file), gstinNumber,
///    countryCode, isActive
///  - Validation: email `^[^\s@]+@[^\s@]+\.com$`, DOB between 8-100 years
///    old, phone 10-15 digits and numeric-only
///  - 400 on save -> "This email is already registered." under email field
///  - Success -> confirmation dialog, then reload in read-only view
///
/// Read-only view vs. edit view exactly mirrors the source's two-mode
/// layout, rebuilt mobile-first as a single scrollable column instead of
/// the original's label/input row grid.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  bool _isEditing = false;

  Map<String, dynamic> _userData = {
    'username': '', 'email': '', 'phone': '', 'gstinNumber': '',
    'dob': '', 'countryCode': '', 'isActive': true,
  };
  PlatformFile? _newProfileFile;

  final _errors = <String, String?>{'username': null, 'email': null, 'dob': null, 'gstinNumber': null, 'phone': null};

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.com$');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final email = await SessionManager.instance.email;
    if (email == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/student/users/$email');
      final data = Map<String, dynamic>.from(res.data as Map);
      setState(() => _userData = data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        context.go('/unauthorized');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleChange(String name, String value) {
    String? error;
    switch (name) {
      case 'email':
        error = _emailRegex.hasMatch(value) ? null : 'Please enter a valid email address';
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
      case 'phone':
        final digitsOnly = RegExp(r'^\d+$').hasMatch(value);
        error = value.length < 10
            ? 'Phone number must be at least 10 digits'
            : value.length > 15
                ? 'Phone number cannot be longer than 15 digits'
                : digitsOnly ? null : 'Please enter a valid phone number (digits only)';
        break;
    }
    setState(() {
      _errors[name] = error;
      _userData[name] = value;
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _newProfileFile = result.files.first);
  }

  bool get _hasErrors => _errors.values.any((e) => e != null);

  Future<void> _handleSubmit() async {
    if (_hasErrors) return;
    try {
      final formData = FormData.fromMap({
        'username': _userData['username'],
        'email': _userData['email'],
        'dob': _userData['dob'] ?? '',
        'phone': _userData['phone'],
        if (_newProfileFile?.bytes != null)
          'profile': MultipartFile.fromBytes(_newProfileFile!.bytes!, filename: _newProfileFile!.name),
        'gstinNumber': _userData['gstinNumber'],
        'countryCode': _userData['countryCode'],
        'isActive': '${_userData['isActive'] ?? true}',
      });
      final res = await ApiClient.instance.dio.patch('/Edit/self', data: formData);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Updated!'),
            content: const Text('Profile Updated successfully!'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        setState(() {
          _isEditing = false;
          _newProfileFile = null;
        });
        _fetchData();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        setState(() => _errors['email'] = 'This email is already registered.');
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Connection Error'),
            content: Text('Could not reach the server (${e.type.name}).\n\n${e.message ?? ''}'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safeBack(context),
        ),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditing = false)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isEditing ? _editForm() : _readOnlyView(),
            ),
    );
  }

  Widget _avatar() {
    Uint8List? bytes = _newProfileFile?.bytes;
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFFF0F4F8),
        backgroundImage: bytes != null ? MemoryImage(bytes) : null,
        child: bytes == null ? const Icon(Icons.person, size: 48, color: Colors.grey) : null,
      ),
    );
  }

  Widget _readOnlyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _avatar(),
        const SizedBox(height: 24),
        _readOnlyField('Name', '${_userData['username'] ?? ''}'),
        _readOnlyField('Email', '${_userData['email'] ?? ''}'),
        _readOnlyField('Date of Birth', '${_userData['dob'] ?? ''}'),
        _readOnlyField('Gstin Number', '${_userData['gstinNumber'] ?? ''}'),
        _readOnlyField('Phone', '${_userData['countryCode'] ?? ''}${_userData['phone'] ?? ''}'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _isEditing = true),
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(value.isEmpty ? '—' : value),
          ),
        ],
      ),
    );
  }

  Widget _editForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _avatar(),
        const SizedBox(height: 8),
        Center(child: OutlinedButton(onPressed: _pickImage, child: const Text('Upload'))),
        const SizedBox(height: 24),
        TextField(
          decoration: InputDecoration(labelText: 'Name', errorText: _errors['username']),
          controller: TextEditingController(text: '${_userData['username'] ?? ''}'),
          onChanged: (v) => _handleChange('username', v),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Email', errorText: _errors['email']),
          controller: TextEditingController(text: '${_userData['email'] ?? ''}'),
          onChanged: (v) => _handleChange('email', v),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Date of Birth', errorText: _errors['dob']),
          readOnly: true,
          controller: TextEditingController(text: '${_userData['dob'] ?? ''}'),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse('${_userData['dob']}') ?? DateTime(DateTime.now().year - 25),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (date != null) _handleChange('dob', date.toIso8601String().split('T').first);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Gstin Number', errorText: _errors['gstinNumber']),
          controller: TextEditingController(text: '${_userData['gstinNumber'] ?? ''}'),
          onChanged: (v) => _handleChange('gstinNumber', v),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Phone *',
            errorText: _errors['phone'],
            prefixText: '${_userData['countryCode'] ?? ''} ',
          ),
          keyboardType: TextInputType.phone,
          controller: TextEditingController(text: '${_userData['phone'] ?? ''}'),
          onChanged: (v) => _handleChange('phone', v),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _hasErrors ? null : _handleSubmit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
