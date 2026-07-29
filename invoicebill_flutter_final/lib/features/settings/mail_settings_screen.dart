import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

/// Port of `src/UserSettings/MailSettings.js`, routed at
/// `/settings/mailSettings`.
///
/// Preserves:
///  - GET /get/mailkeys on load (200 = existing settings shown read-only,
///    204 = none saved yet, starts straight in edit mode)
///  - POST /save/mailkeys the first time (no `id` yet)
///  - PATCH /Edit/mailkeys on subsequent saves (once an `id` exists)
///  - 401 -> redirect to /unauthorized
class MailSettingsScreen extends StatefulWidget {
  const MailSettingsScreen({super.key});

  @override
  State<MailSettingsScreen> createState() => _MailSettingsScreenState();
}

class _MailSettingsScreenState extends State<MailSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;
  Map<String, dynamic> _defaults = {'hostname': '', 'port': '', 'emailid': '', 'password': ''};

  final _hostnameCtl = TextEditingController();
  final _portCtl = TextEditingController(text: '587');
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hostnameCtl.dispose();
    _portCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/get/mailkeys');
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        setState(() {
          _defaults = data;
          _isEdit = false;
          _hostnameCtl.text = '${data['hostname'] ?? ''}';
          _portCtl.text = '${data['port'] ?? '587'}';
          _emailCtl.text = '${data['emailid'] ?? ''}';
          _passwordCtl.text = '${data['password'] ?? ''}';
        });
      } else if (res.statusCode == 204) {
        setState(() => _isEdit = true);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) context.go("/unauthorized");
    } catch (e) {
      debugPrint('Failed to load mail settings: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = {
      'hostname': _hostnameCtl.text,
      'port': _portCtl.text,
      'emailid': _emailCtl.text,
      'password': _passwordCtl.text,
    };
    try {
      final hasId = _defaults['id'] != null;
      final res = hasId
          ? await ApiClient.instance.dio.patch('/Edit/mailkeys', data: payload)
          : await ApiClient.instance.dio.post('/save/mailkeys', data: payload);
      if (res.statusCode == 200 && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(hasId ? 'Updated' : 'Saved!'),
            content: const Text('Email Details Saved Successfully'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        _load();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        context.go("/unauthorized");
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save mail settings')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mail Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _hostnameCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Mail Host Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portCtl,
                  enabled: _isEdit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mail Port *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtl,
                  enabled: _isEdit,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Id *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtl,
                  enabled: _isEdit,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password *'),
                ),
                const SizedBox(height: 24),
                if (_isEdit)
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
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
