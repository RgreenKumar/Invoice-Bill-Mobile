import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/permissions.dart';
import '../../core/utils/safe_back.dart';

/// Port of `src/UserSettings/AddUsers.js`, routed at `/addusers` (add) and
/// `/addusers/:email` (edit - the original used a `?edit=email` query
/// param instead of a path param; this app's router only uses path
/// params elsewhere so the same route is split in two here instead).
///
/// Preserves:
///  - Add mode: name/email/phone validation (phone >= 10 digits),
///    POST /admin/addCashier with a default permission set, 200/201 ->
///    success + back; duplicate email (response body "EMAIL") -> warning
///  - Edit mode: GET /admin/getCashierByEmail?email=, then
///    GET /cashier/permissions/{userId}; only permissions are editable
///    (name/email/phone shown read-only, matching the original where
///    those fields are `disabled` in edit mode); PUT
///    /admin/cashier/permissions/{userId} on save
///  - Permission grid: 8 transaction types (Modules.*) x 4 actions
///    (VIEW/CREATE/EDIT/DELETE), with row/column "toggle all"
///  - "Reset to defaults" button (add mode only, matches original)
///
/// MOBILE-FIRST REWRITE: the original was a fixed 2-panel desktop layout
/// (form on the left, wide 4-column permission table on the right).
/// Rebuilt as a single scrollable column: form fields first, then the
/// permission grid as a list of expandable rows with per-action chips
/// instead of a table that would force horizontal scrolling on a phone.
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key, this.editEmail});

  final String? editEmail;

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  static const _transactionTypes = [
    Modules.saleInvoice,
    Modules.invoicePos,
    Modules.estimateQuotation,
    Modules.addItem,
    Modules.viewItem,
    Modules.customer,
    Modules.parties,
    Modules.stockAdjustment,
  ];
  static const _columns = ['VIEW', 'CREATE', 'EDIT', 'DELETE'];

  static const _defaults = {
    'Sale Invoice': {'VIEW': true, 'CREATE': true, 'EDIT': false, 'DELETE': false},
    'Invoice POS': {'VIEW': true, 'CREATE': true, 'EDIT': false, 'DELETE': false},
    'Estimate Quotation': {'VIEW': true, 'CREATE': true, 'EDIT': false, 'DELETE': false},
    'Add Item': {'VIEW': true, 'CREATE': true, 'EDIT': false, 'DELETE': false},
    'View Item': {'VIEW': true, 'CREATE': false, 'EDIT': false, 'DELETE': false},
    'Customer': {'VIEW': true, 'CREATE': false, 'EDIT': false, 'DELETE': false},
    'Parties': {'VIEW': true, 'CREATE': false, 'EDIT': false, 'DELETE': false},
    'Stock Adjustment': {'VIEW': false, 'CREATE': false, 'EDIT': false, 'DELETE': false},
  };

  bool get _isEditMode => widget.editEmail != null && widget.editEmail!.isNotEmpty;

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  int? _userId;

  bool _fetchLoading = false;
  bool _saving = false;

  late Map<String, Map<String, bool>> _permissions = _buildDefaults();

  static Map<String, Map<String, bool>> _buildDefaults() {
    return {
      for (final t in _transactionTypes)
        t: Map<String, bool>.from(_defaults[t] ?? {'VIEW': false, 'CREATE': false, 'EDIT': false, 'DELETE': false}),
    };
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _fetchCashier(widget.editEmail!);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _fetchCashier(String email) async {
    setState(() => _fetchLoading = true);
    try {
      final userRes = await ApiClient.instance.dio
          .get('/admin/getCashierByEmail', queryParameters: {'email': email});
      final cashier = Map<String, dynamic>.from(userRes.data as Map);
      _nameCtl.text = '${cashier['username'] ?? ''}';
      _emailCtl.text = '${cashier['email'] ?? ''}';
      _phoneCtl.text = '${cashier['phone'] ?? ''}';
      _userId = cashier['userId'] as int?;

      final permRes = await ApiClient.instance.dio.get('/cashier/permissions/$_userId');
      final permObj = _buildDefaults();
      if (permRes.data is List) {
        for (final p in (permRes.data as List)) {
          final m = Map<String, dynamic>.from(p as Map);
          final name = '${m['moduleName']}';
          if (permObj.containsKey(name)) {
            permObj[name] = {
              'VIEW': m['canView'] == true,
              'CREATE': m['canCreate'] == true,
              'EDIT': m['canEdit'] == true,
              'DELETE': m['canDelete'] == true,
            };
          }
        }
      }
      setState(() => _permissions = permObj);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to load cashier data.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchLoading = false);
    }
  }

  void _toggleCell(String txn, String col) {
    setState(() => _permissions[txn]![col] = !_permissions[txn]![col]!);
  }

  void _toggleRow(String txn) {
    final allTrue = _columns.every((c) => _permissions[txn]![c] == true);
    setState(() {
      for (final c in _columns) {
        _permissions[txn]![c] = !allTrue;
      }
    });
  }

  void _toggleColumn(String col) {
    final allTrue = _transactionTypes.every((t) => _permissions[t]![col] == true);
    setState(() {
      for (final t in _transactionTypes) {
        _permissions[t]![col] = !allTrue;
      }
    });
  }

  List<Map<String, dynamic>> _buildPayload() {
    return _transactionTypes
        .map((t) => {
              'moduleName': t,
              'canView': _permissions[t]!['VIEW'],
              'canCreate': _permissions[t]!['CREATE'],
              'canEdit': _permissions[t]!['EDIT'],
              'canDelete': _permissions[t]!['DELETE'],
            })
        .toList();
  }

  Future<void> _submit() async {
    final payload = _buildPayload();
    if (_isEditMode) {
      setState(() => _saving = true);
      try {
        await ApiClient.instance.dio.put('/admin/cashier/permissions/$_userId', data: payload);
        if (mounted) {
          await showDialog(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Permissions updated. Cashier must re-login to see changes.'),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
            ),
          );
          if (mounted) safeBack(context, fallback: '/settings/users');
        }
      } on DioException catch (e) {
        _handleSubmitError(e);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    if (_nameCtl.text.trim().isEmpty) {
      _warn('Please enter full name.');
      return;
    }
    if (_emailCtl.text.trim().isEmpty) {
      _warn('Please enter email.');
      return;
    }
    if (_phoneCtl.text.trim().isEmpty) {
      _warn('Please enter phone number.');
      return;
    }
    if (_phoneCtl.text.trim().length < 10) {
      _warn('Please enter a valid 10 digit phone number.');
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await ApiClient.instance.dio.post('/admin/addCashier', data: {
        'username': _nameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'phone': _phoneCtl.text.trim(),
        'permissions': payload,
      });
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Cashier added successfully.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) safeBack(context, fallback: '/settings/users');
      }
    } on DioException catch (e) {
      _handleSubmitError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleSubmitError(DioException e) {
    if (!mounted) return;
    if (e.response?.statusCode == 401) {
      context.go('/unauthorized');
      return;
    }
    final message = e.response?.data == 'EMAIL'
        ? 'This email is already registered.'
        : (e.response?.data is Map ? '${(e.response?.data as Map)['message'] ?? 'Failed to save.'}' : 'Failed to save.');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
      ),
    );
  }

  void _warn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Update Permissions' : 'Add User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => safeBack(context, fallback: '/settings/users'),
          ),
        ],
      ),
      body: _fetchLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameCtl,
                  enabled: !_isEditMode,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtl,
                  enabled: !_isEditMode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    helperText: _isEditMode ? null : 'Cashier will receive login credentials on this email.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtl,
                  enabled: !_isEditMode,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number *'),
                ),
                const SizedBox(height: 12),
                const InputDecorator(
                  decoration: InputDecoration(labelText: 'User Role'),
                  child: Text('Cashier'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cashier Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (!_isEditMode)
                      TextButton.icon(
                        onPressed: () => setState(() => _permissions = _buildDefaults()),
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: const Text('Reset'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final col in _columns)
                      ActionChip(
                        label: Text('All $col'),
                        onPressed: () => _toggleColumn(col),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final txn in _transactionTypes) _permissionRow(txn),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => safeBack(context, fallback: '/settings/users'),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isEditMode ? 'Update' : 'Add User'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _permissionRow(String txn) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _toggleRow(txn),
              child: Text(txn, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final col in _columns)
                  FilterChip(
                    label: Text(col, style: const TextStyle(fontSize: 11)),
                    selected: _permissions[txn]![col] == true,
                    onSelected: (_) => _toggleCell(txn, col),
                    selectedColor: const Color(0xFFE0F5EC),
                    checkmarkColor: const Color(0xFF1A9E6E),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
