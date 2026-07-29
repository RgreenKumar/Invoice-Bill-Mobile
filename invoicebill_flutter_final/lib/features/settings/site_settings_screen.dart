import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';

/// Port of `src/UserSettings/Sitesettings.js`.
///
/// Preserves:
///  - GET /Get/labellings on load (siteUrl/title/sitelogo/siteicon/titleicon)
///  - POST /save/labellings as multipart form data (site logo/icon/favicon
///    uploaded as files, matching the original FormData usage)
///  - View/Edit toggle gated by getPermission(null, ...) (MODULES.SETTINGS
///    is undefined upstream, same as SettingsHomeScreen)
///  - Only rendered when Activeprofile === "VPS" (enforced by the caller)
class SiteSettingsScreen extends StatefulWidget {
  const SiteSettingsScreen({super.key});

  @override
  State<SiteSettingsScreen> createState() => _SiteSettingsScreenState();
}

class _SiteSettingsScreenState extends State<SiteSettingsScreen> {
  bool _loading = true;
  bool _isEdit = false;
  bool _saving = false;

  final _siteUrlCtl = TextEditingController();
  final _titleCtl = TextEditingController();

  PlatformFile? _sitelogo;
  PlatformFile? _siteicon;
  PlatformFile? _titleicon;

  Uint8List? _sitelogoBase64Preview;
  Uint8List? _siteiconBase64Preview;
  Uint8List? _titleiconBase64Preview;

  bool get _canCreate => getPermission(null, 'canCreate');
  bool get _canEdit => getPermission(null, 'canEdit');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _siteUrlCtl.dispose();
    _titleCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/Get/labellings');
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        _siteUrlCtl.text = '${data['siteUrl'] ?? ''}';
        _titleCtl.text = '${data['title'] ?? ''}';
        setState(() {
          _sitelogoBase64Preview = _decode(data['sitelogo']);
          _siteiconBase64Preview = _decode(data['siteicon']);
          _titleiconBase64Preview = _decode(data['titleicon']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching site settings: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Uint8List? _decode(dynamic b64) {
    if (b64 == null) return null;
    try {
      return base64Decode('$b64');
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFile(String field) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: field == 'titleicon' ? ['ico'] : ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 100 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File size must be 100 KB or smaller')));
      }
      return;
    }
    setState(() {
      if (field == 'sitelogo') {
        _sitelogo = file;
        _sitelogoBase64Preview = file.bytes;
      } else if (field == 'siteicon') {
        _siteicon = file;
        _siteiconBase64Preview = file.bytes;
      } else {
        _titleicon = file;
        _titleiconBase64Preview = file.bytes;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final formData = FormData.fromMap({
        'siteUrl': _siteUrlCtl.text,
        'title': _titleCtl.text,
        if (_sitelogo != null)
          'sitelogo': MultipartFile.fromBytes(_sitelogo!.bytes!, filename: _sitelogo!.name),
        if (_siteicon != null)
          'siteicon': MultipartFile.fromBytes(_siteicon!.bytes!, filename: _siteicon!.name),
        if (_titleicon != null)
          'titleicon': MultipartFile.fromBytes(_titleicon!.bytes!, filename: _titleicon!.name),
      });
      final res = await ApiClient.instance.dio.post('/save/labellings', data: formData);
      if (res.statusCode == 200 && mounted) {
        if (res.data is Map) {
          await context.read<GlobalStateProvider>().setSiteSettingsMap(Map<String, dynamic>.from(res.data as Map));
        }
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved'),
            content: const Text('Site settings saved successfully'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) setState(() => _isEdit = false);
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save site settings')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _siteUrlCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Site Url'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Tab Title'),
                ),
                const SizedBox(height: 16),
                _imageRow('Site Logo (150x50px .png)', _sitelogoBase64Preview, () => _pickFile('sitelogo')),
                const SizedBox(height: 16),
                _imageRow('Site Icon (200x200px .png)', _siteiconBase64Preview, () => _pickFile('siteicon')),
                const SizedBox(height: 16),
                _imageRow('Favicon (16x16px .ico)', _titleiconBase64Preview, () => _pickFile('titleicon')),
                const SizedBox(height: 24),
                if (_isEdit && _canCreate)
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  )
                else if (_canEdit)
                  FilledButton.tonal(
                    onPressed: () => setState(() => _isEdit = true),
                    child: const Text('Edit'),
                  ),
              ],
            ),
    );
  }

  Widget _imageRow(String label, Uint8List? preview, VoidCallback onPick) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              if (_isEdit)
                OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Choose file'),
                ),
            ],
          ),
        ),
        if (preview != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: Image.memory(preview, fit: BoxFit.contain),
            ),
          ),
      ],
    );
  }
}
