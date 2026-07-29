import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

/// Port of `src/UserSettings/FooterDetails.js`, routed at
/// `/settings/footer`.
///
/// Preserves:
///  - GET /Get/FooterDetails on load (200 = shown read-only, 204 = none
///    saved yet, starts in edit mode)
///  - POST /save/FooterDetails on save (same endpoint used for both the
///    first save and subsequent edits in the original file)
class FooterSettingsScreen extends StatefulWidget {
  const FooterSettingsScreen({super.key});

  @override
  State<FooterSettingsScreen> createState() => _FooterSettingsScreenState();
}

class _FooterSettingsScreenState extends State<FooterSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;

  final _copyrightCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final _supportMailCtl = TextEditingController();
  final _institutionMailCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _copyrightCtl.dispose();
    _contactCtl.dispose();
    _supportMailCtl.dispose();
    _institutionMailCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/Get/FooterDetails');
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        setState(() {
          _isEdit = false;
          _copyrightCtl.text = '${data['copyright'] ?? ''}';
          _contactCtl.text = '${data['contact'] ?? ''}';
          _supportMailCtl.text = '${data['supportmail'] ?? ''}';
          _institutionMailCtl.text = '${data['institutionmail'] ?? ''}';
        });
      } else if (res.statusCode == 204) {
        setState(() => _isEdit = true);
      }
    } catch (e) {
      debugPrint('Failed to load footer details: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = {
      'copyright': _copyrightCtl.text,
      'contact': _contactCtl.text,
      'supportmail': _supportMailCtl.text,
      'institutionmail': _institutionMailCtl.text,
    };
    try {
      final res = await ApiClient.instance.dio.post('/save/FooterDetails', data: payload);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved'),
            content: const Text('Footer Settings saved successfully'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        _load();
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save footer details')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Footer Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _copyrightCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Copyright Content *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactCtl,
                  enabled: _isEdit,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Mobile *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _supportMailCtl,
                  enabled: _isEdit,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Support Mail *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _institutionMailCtl,
                  enabled: _isEdit,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Institution Mail *'),
                ),
                const SizedBox(height: 24),
                if (_isEdit)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.maybePop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  )
                else
                  FilledButton.tonal(
                    onPressed: () => setState(() => _isEdit = true),
                    child: const Text('Edit'),
                  ),
              ],
            ),
    );
  }
}
