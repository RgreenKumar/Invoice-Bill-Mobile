import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';

/// Port of `src/UserSettings/DisplayName.js`, routed at
/// `/settings/displayname`.
///
/// Controls the custom "Trainer"/"Student" labels shown throughout the
/// sidebar/nav as "Suppliers"/"Customers" (see Sidebar.js reading
/// `displayname.trainer_name` / `displayname.student_name`).
///
/// Preserves:
///  - GET /get/displayName on load (200 = shown read-only, 204/404 = none
///    saved yet, starts in edit mode)
///  - POST /post/displayname the first time, PATCH /edit/displayname once
///    an `id` exists
///  - Updates the cached displayname in GlobalStateProvider (mirrors
///    `sessionStorage.setItem("displayname", ...)`) so the sidebar
///    reflects the new labels immediately
class DisplayNameScreen extends StatefulWidget {
  const DisplayNameScreen({super.key});

  @override
  State<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends State<DisplayNameScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;
  Map<String, dynamic> _defaults = {};

  final _adminCtl = TextEditingController();
  final _trainerCtl = TextEditingController();
  final _studentCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _adminCtl.dispose();
    _trainerCtl.dispose();
    _studentCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/get/displayName');
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        setState(() {
          _defaults = data;
          _isEdit = false;
          _adminCtl.text = '${data['admin_name'] ?? ''}';
          _trainerCtl.text = '${data['trainer_name'] ?? ''}';
          _studentCtl.text = '${data['student_name'] ?? ''}';
        });
      } else if (res.statusCode == 204) {
        setState(() => _isEdit = true);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        setState(() => _isEdit = true);
      } else if (status == 401 && mounted) {
        context.go('/unauthorized');
      }
    } catch (e) {
      debugPrint('Failed to load display name settings: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = {
      'admin_name': _adminCtl.text,
      'trainer_name': _trainerCtl.text,
      'student_name': _studentCtl.text,
      'isActive': true,
    };
    try {
      final hasId = _defaults['id'] != null;
      final res = hasId
          ? await ApiClient.instance.dio.patch('/edit/displayname', data: payload)
          : await ApiClient.instance.dio.post('/post/displayname', data: payload);
      if (res.statusCode == 200 && mounted) {
        await context.read<GlobalStateProvider>().setDisplayNameMap(payload);
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(hasId ? 'Updated' : 'Saved!'),
            content: const Text('Role Details Saved Successfully'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        _load();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        context.go('/unauthorized');
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save role display names')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role Display Names')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _adminCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Admin Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _trainerCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Supplier (Trainer) Label *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _studentCtl,
                  enabled: _isEdit,
                  decoration: const InputDecoration(labelText: 'Customer (Student) Label *'),
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
