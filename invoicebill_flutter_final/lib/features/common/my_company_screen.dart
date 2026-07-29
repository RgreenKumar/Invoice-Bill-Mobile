import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/safe_back.dart';

/// Port of `src/Common Components/MyCompany.js`, routed at
/// `/admin/mycompany`.
///
/// Preserves:
///  - GET /admin/getMyCompany on load
///  - POST /admin/saveMyCompany with a JSON payload (not multipart -
///    logo/signature are sent as raw base64 strings, `null` when
///    unchanged) matching the exact field names: businessName,
///    phoneNumber, gstin, emailId, countryCode, businessType,
///    businessCategory, state, pincode, businessAddress, logo, signature
///  - Read-only vs. editable mode toggle, same field set
///  - Business Type / Category / State dropdown option lists, identical
///    values to the source
///
/// Rebuilt mobile-first: the original's 3-column layout (Business
/// Details | More Details | Address+Signature) becomes a single
/// scrollable column, grouped under the same three headings.
class MyCompanyScreen extends StatefulWidget {
  const MyCompanyScreen({super.key});

  @override
  State<MyCompanyScreen> createState() => _MyCompanyScreenState();
}

class _MyCompanyScreenState extends State<MyCompanyScreen> {
  bool _isEditing = false;
  bool _loading = false;

  final _companyData = <String, String>{
    'businessName': '', 'phoneNumber': '', 'gstin': '', 'emailId': '',
    'countryCode': '+91', 'businessType': '', 'businessCategory': '',
    'state': '', 'pincode': '', 'businessAddress': '',
  };

  Uint8List? _logoBytes;
  Uint8List? _signatureBytes;
  PlatformFile? _newLogoFile;
  PlatformFile? _newSignatureFile;

  static const _businessTypes = [
    'Sole Proprietorship', 'Partnership', 'Private Limited', 'Public Limited', 'LLP'
  ];
  static const _businessCategories = [
    'Retail', 'Wholesale', 'Manufacturing', 'Services', 'Education', 'Healthcare', 'Technology'
  ];
  static const _states = [
    'Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh', 'Maharashtra',
    'Delhi', 'Gujarat', 'Rajasthan', 'Uttar Pradesh', 'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyCompany();
  }

  Uint8List? _decodeBase64(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return const Base64Decoder().convert(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchMyCompany() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/getMyCompany');
      if (res.statusCode == 200 && res.data != null && res.data is Map) {
        final data = res.data as Map;
        setState(() {
          _companyData['businessName'] = '${data['businessName'] ?? ''}';
          _companyData['phoneNumber'] = '${data['phoneNumber'] ?? ''}';
          _companyData['gstin'] = '${data['gstin'] ?? ''}';
          _companyData['emailId'] = '${data['emailId'] ?? ''}';
          _companyData['countryCode'] = '${data['countryCode'] ?? '+91'}';
          _companyData['businessType'] = '${data['businessType'] ?? ''}';
          _companyData['businessCategory'] = '${data['businessCategory'] ?? ''}';
          _companyData['state'] = '${data['state'] ?? ''}';
          _companyData['pincode'] = '${data['pincode'] ?? ''}';
          _companyData['businessAddress'] = '${data['businessAddress'] ?? ''}';
          _logoBytes = _decodeBase64(data['logo'] as String?);
          _signatureBytes = _decodeBase64(data['signature'] as String?);
        });
      }
    } catch (e) {
      debugPrint('Error fetching company details: $e');
    }
  }

  Future<void> _pickLogo() async {
    if (!_isEditing) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _newLogoFile = result.files.first;
      _logoBytes = result.files.first.bytes;
    });
  }

  Future<void> _pickSignature() async {
    if (!_isEditing) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _newSignatureFile = result.files.first;
      _signatureBytes = result.files.first.bytes;
    });
  }

  Future<void> _handleSave() async {
    setState(() => _loading = true);
    try {
      final payload = {
        'businessName': _companyData['businessName'],
        'phoneNumber': _companyData['phoneNumber'],
        'gstin': _companyData['gstin'],
        'emailId': _companyData['emailId'],
        'countryCode': _companyData['countryCode'],
        'businessType': _companyData['businessType'],
        'businessCategory': _companyData['businessCategory'],
        'state': _companyData['state'],
        'pincode': _companyData['pincode'],
        'businessAddress': _companyData['businessAddress'],
        'logo': _newLogoFile?.bytes != null ? base64Encode(_newLogoFile!.bytes!) : null,
        'signature': _newSignatureFile?.bytes != null ? base64Encode(_newSignatureFile!.bytes!) : null,
      };
      final res = await ApiClient.instance.dio.post('/admin/saveMyCompany', data: payload);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved!'),
            content: const Text('Company details saved successfully.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        setState(() {
          _isEditing = false;
          _newLogoFile = null;
          _newSignatureFile = null;
        });
        _fetchMyCompany();
      }
    } catch (e) {
      debugPrint('Error saving company details: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to save company details!'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Company'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => safeBack(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _logoPicker(),
            const SizedBox(height: 24),
            _sectionHeader('Business Details'),
            _field('Business Name *', 'businessName'),
            const SizedBox(height: 12),
            _phoneField(),
            const SizedBox(height: 12),
            _field('GSTIN', 'gstin'),
            const SizedBox(height: 12),
            _field('Email ID', 'emailId'),
            const SizedBox(height: 24),
            _sectionHeader('More Details'),
            _dropdown('Business Type', 'businessType', _businessTypes),
            const SizedBox(height: 12),
            _dropdown('Business Category', 'businessCategory', _businessCategories),
            const SizedBox(height: 12),
            _dropdown('State', 'state', _states),
            const SizedBox(height: 12),
            _field('Pincode', 'pincode'),
            const SizedBox(height: 24),
            _sectionHeader('Address & Signature'),
            _field('Business Address', 'businessAddress', maxLines: 4),
            const SizedBox(height: 16),
            _signaturePicker(),
            const SizedBox(height: 24),
            if (_isEditing)
              FilledButton(
                onPressed: _loading ? null : _handleSave,
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              )
            else
              FilledButton(
                onPressed: () => setState(() => _isEditing = true),
                child: const Text('Edit'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _logoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickLogo,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFE8F0FE),
              backgroundImage: _logoBytes != null ? MemoryImage(_logoBytes!) : null,
              child: _logoBytes == null
                  ? const Text('Add\nLogo', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7A9CC6), fontSize: 13))
                  : null,
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Color(0xFF555555)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _signaturePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Signature', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickSignature,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCCCCCC), style: BorderStyle.solid, width: 2),
            ),
            child: Center(
              child: _signatureBytes != null
                  ? Image.memory(_signatureBytes!, height: 80, fit: BoxFit.contain)
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 28, color: Color(0xFFAAAAAA)),
                        SizedBox(height: 4),
                        Text('Upload Signature', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, String key, {int maxLines = 1}) {
    return TextField(
      readOnly: !_isEditing,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: _isEditing ? null : const Color(0xFFF0F0F0)),
      controller: TextEditingController(text: _companyData[key]),
      onChanged: (v) => _companyData[key] = v,
    );
  }

  Widget _phoneField() {
    return TextField(
      readOnly: !_isEditing,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixText: '${_companyData['countryCode']} ',
        filled: true,
        fillColor: _isEditing ? null : const Color(0xFFF0F0F0),
      ),
      controller: TextEditingController(text: _companyData['phoneNumber']),
      onChanged: (v) => _companyData['phoneNumber'] = v,
    );
  }

  Widget _dropdown(String label, String key, List<String> options) {
    final value = _companyData[key]!.isEmpty ? null : _companyData[key];
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: null, child: Text('Select $label')),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: _isEditing ? (v) => setState(() => _companyData[key] = v ?? '') : null,
    );
  }
}
