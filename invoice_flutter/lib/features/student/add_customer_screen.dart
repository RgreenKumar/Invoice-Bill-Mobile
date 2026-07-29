import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';
import '../../core/utils/safe_back.dart';

/// Port of `src/Student/AddCustomer.js`.
///
/// MOBILE-FIRST REWRITE: the original (and an earlier pass of this file)
/// laid the "GST & Address" tab out as three side-by-side columns
/// (dropdowns+email+OTP | billing address | shipping address), which
/// overflows/breaks on phone-width screens - reported explicitly as "not
/// mobile friendly". Rebuilt here as a single scrollable column, same
/// pattern as `AddItemScreen`: every field stacked vertically, tabs kept
/// as a simple `ChoiceChip` row instead of a `TabBar`+3-column grid.
///
/// Preserves the same logic as before:
///  - 3 sections: GST & Address, Credit & Balance, Additional Fields
///  - Email OTP verification gate (POST /auth/send-otp, /auth/verify-otp),
///    only required when `generalSettings.otpservice` is true
///  - POST /admin/addParty with the same payload shape
///  - Validation: name required, email must match
///    `^[^\s@]+@[^\s@]+\.com$` when provided, phone validated as digits
///  - 403 -> "Only ADMIN can add party!" dialog
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key, this.partyType = 'CUSTOMER'});

  final String partyType;

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  String _activeTab = 'basic';
  bool _shippingEnabled = false;

  final _formData = <String, dynamic>{
    'name': '', 'gstin': '', 'phone': '', 'email': '',
    'gstType': 'unregistered_consumer', 'state': '',
    'billingAddress': '', 'shippingAddress': '',
    'openingBalance': '', 'asOfDate': '',
    'creditLimitType': 'no_limit', 'creditAmount': '',
    'aadhaarNo': '', 'drugLicenseNo': '', 'panNo': '',
  };

  final _errors = <String, String?>{'name': null, 'phone': null, 'email': null, 'otp': null};

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isSendingOtp = false;
  String _otp = '';
  bool _submitting = false;

  static const _states = [
    'Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh', 'Maharashtra',
    'Delhi', 'Gujarat', 'Rajasthan', 'Uttar Pradesh', 'West Bengal',
  ];

  bool get _canCreate => getPermission(Modules.customer, 'canCreate');

  void _handleChange(String name, String value) {
    setState(() {
      _formData[name] = value;
      if (name == 'name') {
        _errors['name'] = value.isEmpty ? 'Please enter a valid name' : null;
      }
      if (name == 'email' && value.isNotEmpty) {
        final ok = RegExp(r'^[^\s@]+@[^\s@]+\.com$').hasMatch(value);
        _errors['email'] = ok ? null : 'Please enter a valid email address';
      }
    });
  }

  void _handlePhoneChange(String value) {
    setState(() {
      _formData['phone'] = value;
      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
      _errors['phone'] = digitsOnly.length >= 7 ? null : 'Enter a valid Phone number';
    });
  }

  Future<void> _handleSendOtp() async {
    if (_formData['email'].isEmpty || _errors['email'] != null) {
      setState(() => _errors['email'] = _formData['email'].isEmpty ? 'Email is required' : _errors['email']);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Sent! Please check your email.')));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verified!')));
        }
      }
    } catch (_) {
      setState(() => _errors['otp'] = 'Invalid or expired OTP');
    }
  }

  Future<void> _handleSubmit() async {
    final otpService = context.read<GlobalStateProvider>().generalSettings['otpservice'] == true;
    if (otpService && !_otpVerified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please Verify Your Email First!')));
      return;
    }
    if ((_formData['name'] as String).isEmpty) {
      setState(() => _errors['name'] = 'Name is required');
      return;
    }

    final payload = {
      'name': _formData['name'],
      'gstin': _formData['gstin'],
      'phone': _formData['phone'],
      'email': _formData['email'],
      'gstType': _formData['gstType'],
      'state': _formData['state'],
      'billingAddress': _formData['billingAddress'],
      'shippingAddress': _formData['shippingAddress'],
      'openingBalance': (_formData['openingBalance'] as String).isEmpty ? null : _formData['openingBalance'],
      'asOfDate': (_formData['asOfDate'] as String).isEmpty ? null : _formData['asOfDate'],
      'creditLimit': _formData['creditLimitType'] == 'custom',
      'creditAmount': _formData['creditLimitType'] == 'custom' ? _formData['creditAmount'] : null,
      'aadhaarNo': _formData['aadhaarNo'],
      'drugLicenseNo': _formData['drugLicenseNo'],
      'panNo': _formData['panNo'],
      'partyType': widget.partyType,
    };

    setState(() => _submitting = true);
    try {
      final res = await ApiClient.instance.dio.post('/admin/addParty', data: payload);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Added!'),
            content: Text(
                'New ${widget.partyType == 'CUSTOMER' ? 'Customer' : 'Supplier'} added successfully!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        if (mounted) safeBack(context, fallback: '/view/Students');
      }
    } on DioException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(e.response?.statusCode == 403 ? 'Unauthorized!' : 'Error!'),
            content: Text(e.response?.statusCode == 403
                ? 'Only ADMIN can add party!'
                : 'Something went wrong. Please try again.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final generalSettings = context.watch<GlobalStateProvider>().generalSettings;
    final label = widget.partyType == 'CUSTOMER' ? 'Customer' : 'Supplier';

    return Scaffold(
      appBar: AppBar(
        title: Text('Add $label'),
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => safeBack(context, fallback: '/view/Students'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(labelText: '$label Name *', errorText: _errors['name']),
              onChanged: (v) => _handleChange('name', v),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'GSTIN'),
              onChanged: (v) => _handleChange('gstin', v),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Phone Number', errorText: _errors['phone']),
              keyboardType: TextInputType.phone,
              onChanged: _handlePhoneChange,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                _tab('GST & Address', 'basic'),
                _tab('Credit & Balance', 'account'),
                _tab('Additional Fields', 'additional'),
              ],
            ),
            const SizedBox(height: 16),
            if (_activeTab == 'basic') _basicTab(generalSettings),
            if (_activeTab == 'account') _accountTab(),
            if (_activeTab == 'additional') _additionalTab(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => safeBack(context, fallback: '/view/Students'),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_canCreate)
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _handleSubmit,
                      child: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, String key) {
    return ChoiceChip(
      label: Text(label),
      selected: _activeTab == key,
      onSelected: (_) => setState(() => _activeTab = key),
    );
  }

  Widget _basicTab(Map<String, dynamic> generalSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _formData['gstType'],
          decoration: const InputDecoration(labelText: 'GST Type'),
          items: const [
            DropdownMenuItem(value: 'unregistered_consumer', child: Text('Unregistered/Consumer')),
            DropdownMenuItem(value: 'registered_regular', child: Text('Registered Business - Regular')),
            DropdownMenuItem(value: 'registered_composition', child: Text('Registered Business - Composition')),
          ],
          onChanged: (v) => setState(() => _formData['gstType'] = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _formData['state'].isEmpty ? null : _formData['state'],
          decoration: const InputDecoration(labelText: 'State'),
          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _formData['state'] = v ?? ''),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(labelText: 'Email ID', errorText: _errors['email']),
          enabled: !_otpVerified,
          onChanged: (v) => _handleChange('email', v),
        ),
        if (generalSettings['otpservice'] == true) ...[
          const SizedBox(height: 8),
          if (_otpVerified)
            const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 4), Text('Verified')])
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_formData['email'].isEmpty || _errors['email'] != null || _isSendingOtp)
                    ? null : _handleSendOtp,
                child: Text(_isSendingOtp ? 'Sending...' : (_otpSent ? 'Resend OTP' : 'Send OTP')),
              ),
            ),
          if (_otpSent && !_otpVerified) ...[
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(hintText: 'Enter 6-digit OTP', errorText: _errors['otp']),
              maxLength: 6,
              onChanged: (v) => setState(() => _otp = v.replaceAll(RegExp(r'\D'), '')),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _otp.length == 6 ? _handleVerifyOtp : null,
                child: const Text('Verify OTP'),
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Billing Address', alignLabelWithHint: true),
          maxLines: 4,
          onChanged: (v) => _handleChange('billingAddress', v),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Shipping Address'),
            if (!_shippingEnabled)
              TextButton(onPressed: () => setState(() => _shippingEnabled = true), child: const Text('+ Enable'))
            else
              TextButton(
                onPressed: () => setState(() => _formData['shippingAddress'] = _formData['billingAddress']),
                child: const Text('Copy Billing'),
              ),
          ],
        ),
        if (_shippingEnabled)
          TextField(
            decoration: const InputDecoration(hintText: 'Shipping Address'),
            maxLines: 4,
            controller: TextEditingController(text: _formData['shippingAddress']),
            onChanged: (v) => _formData['shippingAddress'] = v,
          ),
      ],
    );
  }

  Widget _accountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Opening Balance'),
          keyboardType: TextInputType.number,
          onChanged: (v) => _handleChange('openingBalance', v),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'As Of Date'),
          readOnly: true,
          controller: TextEditingController(text: _formData['asOfDate']),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) _handleChange('asOfDate', date.toIso8601String().split('T').first);
          },
        ),
        const SizedBox(height: 16),
        const Text('Credit Limit', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Text('No Limit'),
            Switch(
              value: _formData['creditLimitType'] == 'custom',
              onChanged: (v) => setState(() => _formData['creditLimitType'] = v ? 'custom' : 'no_limit'),
            ),
            const Text('Custom Limit'),
          ],
        ),
        if (_formData['creditLimitType'] == 'custom')
          TextField(
            decoration: const InputDecoration(labelText: 'Credit Limit Amount'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _handleChange('creditAmount', v),
          ),
      ],
    );
  }

  Widget _additionalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Aadhaar No'),
          maxLength: 12,
          onChanged: (v) => _handleChange('aadhaarNo', v),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Drug License No'),
          onChanged: (v) => _handleChange('drugLicenseNo', v),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'PAN No'),
          maxLength: 10,
          onChanged: (v) => _handleChange('panNo', v),
        ),
      ],
    );
  }
}
