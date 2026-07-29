import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

/// Port of `src/UserSettings/ManageUsers.js`, routed at
/// `/settings/users`.
///
/// Preserves:
///  - GET /admin/getCashiers on load
///  - Search by username/email/phone
///  - DELETE /admin/deactivate/cashier?email=&reason= (with a reason
///    prompt, matching the original's modal)
///  - DELETE /admin/activate/cashier?email=
///  - "Add Users" -> /addusers, per-row "Update" -> /addusers/:email (edit)
///
/// MOBILE-FIRST REWRITE: the original rendered a wide `<table>`. Rebuilt
/// as a card list so it fits phone widths without horizontal scrolling.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> _cashiers = [];
  bool _loading = true;
  bool _actionLoading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/admin/getCashiers');
      final list = res.data is List ? res.data as List : [];
      setState(() => _cashiers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      debugPrint('Error fetching cashiers: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _cashiers;
    return _cashiers.where((c) {
      return '${c['username'] ?? ''}'.toLowerCase().contains(q) ||
          '${c['email'] ?? ''}'.toLowerCase().contains(q) ||
          '${c['phone'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openDeactivate(String email) async {
    final reasonCtl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Deactivate Cashier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a reason for deactivating $email'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter reason...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (reasonCtl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason.')));
      }
      return;
    }
    setState(() => _actionLoading = true);
    try {
      await ApiClient.instance.dio.delete('/admin/deactivate/cashier',
          queryParameters: {'email': email, 'reason': reasonCtl.text.trim()});
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to deactivate cashier.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _activate(String email) async {
    setState(() => _actionLoading = true);
    try {
      await ApiClient.instance.dio.delete('/admin/activate/cashier', queryParameters: {'email': email});
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to activate cashier.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addusers'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search), hintText: 'Search users...', isDense: true),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text("You haven't added any users yet", style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              const Text('Add users, assign roles, and let your\nemployees manage your business.',
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final c = _filtered[i];
                            final active = c['isActive'] == true;
                            return Card(
                              child: ListTile(
                                title: Text('${c['username'] ?? '—'}'),
                                subtitle: Text('${c['email'] ?? ''}\n${c['phone'] ?? ''}'),
                                isThreeLine: true,
                                leading: CircleAvatar(
                                  backgroundColor: active ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                                  child: Icon(active ? Icons.check : Icons.close, color: Colors.white, size: 18),
                                ),
                                trailing: PopupMenuButton<String>(
                                  enabled: !_actionLoading,
                                  onSelected: (v) {
                                    if (v == 'edit') context.push('/addusers/${c['email']}');
                                    if (v == 'deactivate') _openDeactivate('${c['email']}');
                                    if (v == 'activate') _activate('${c['email']}');
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit Permissions')),
                                    if (active)
                                      const PopupMenuItem(value: 'deactivate', child: Text('Deactivate'))
                                    else
                                      const PopupMenuItem(value: 'activate', child: Text('Activate')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
