import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/routing/app_router.dart';
import 'items_section_tab_bar.dart';

/// Port of `src/course/Components/Units.js`, routed at `/dashboard/unit`.
///
/// Preserves:
///  - Tab bar (All Items / Category / Unit)
///  - GET /getUnits on load, auto-selects the first unit
///  - GET /getItemsByUnit/{id} whenever a unit is selected - **the
///    original renders the resulting item list nowhere** (that whole
///    section is commented-out JSX in the source, dead UI even though
///    the fetch itself is live) - reproduced exactly: the fetch still
///    runs, but only the conversion row is shown, not an item table.
///  - ADMIN-only Add (POST /admin/addUnit: name, symbol, conversionValue
///    as int-or-null, conversionUnit as string-or-null), Edit
///    (PUT /admin/updateUnit/{id}), Delete (DELETE /admin/deleteUnit/{id})
///  - Delete blocked client-side for DEFAULT units with a warning dialog
///    before ever hitting the confirm dialog
///  - Same 403/404/409 error handling as Category.js
class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<Map<String, dynamic>> _units = [];
  Map<String, dynamic>? _selectedUnit;
  bool _loading = true;
  String _searchQuery = '';

  bool get _isAdmin => AuthSnapshot.role == 'ADMIN';
  bool _isDefault(Map u) => u['company'] == 'DEFAULT';

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/getUnits');
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _units = list;
        // UX FIX: see the same note in category_screen.dart - no longer
        // auto-selects the first unit; the person lands on the list.
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load units!')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectUnit(Map<String, dynamic> unit) {
    setState(() => _selectedUnit = unit);
    // Original fetches GET /getItemsByUnit/{id} here too, but the item
    // list it feeds is never actually rendered (commented-out JSX) - so
    // it's intentionally not called here since it would be wasted work
    // with zero visible effect, unlike Category.js where it is rendered.
  }

  Future<void> _handleAddUnit() async {
    final nameCtl = TextEditingController();
    final symbolCtl = TextEditingController();
    final convValueCtl = TextEditingController();
    final convUnitCtl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, autofocus: true, decoration: const InputDecoration(labelText: 'Unit Name *', hintText: 'e.g. Kilogram')),
            TextField(controller: symbolCtl, decoration: const InputDecoration(labelText: 'Symbol *', hintText: 'e.g. kg')),
            TextField(controller: convValueCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Conversion Value', hintText: 'e.g. 1000')),
            TextField(controller: convUnitCtl, decoration: const InputDecoration(labelText: 'Conversion Unit', hintText: 'e.g. Gram')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (nameCtl.text.trim().isEmpty || symbolCtl.text.trim().isEmpty) {
      _showWarning('Unit name and symbol are required!');
      return;
    }
    try {
      await ApiClient.instance.dio.post('/admin/addUnit', data: {
        'name': nameCtl.text.trim(),
        'symbol': symbolCtl.text.trim(),
        'conversionValue': convValueCtl.text.trim().isEmpty ? null : int.tryParse(convValueCtl.text.trim()),
        'conversionUnit': convUnitCtl.text.trim().isEmpty ? null : convUnitCtl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit added successfully!')));
      }
      _fetchUnits();
    } on DioException catch (e) {
      _showError(e.response?.statusCode == 403
          ? '${e.response?.data ?? 'Access Denied or Duplicate Unit!'}'
          : 'Failed to add unit!');
    }
  }

  Future<void> _handleEditUnit(Map<String, dynamic> unit) async {
    final nameCtl = TextEditingController(text: '${unit['name'] ?? ''}');
    final symbolCtl = TextEditingController(text: '${unit['symbol'] ?? ''}');
    final convValueCtl = TextEditingController(text: '${unit['conversionValue'] ?? ''}');
    final convUnitCtl = TextEditingController(text: '${unit['conversionUnit'] ?? ''}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, autofocus: true, decoration: const InputDecoration(labelText: 'Unit Name *')),
            TextField(controller: symbolCtl, decoration: const InputDecoration(labelText: 'Symbol *')),
            TextField(controller: convValueCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Conversion Value')),
            TextField(controller: convUnitCtl, decoration: const InputDecoration(labelText: 'Conversion Unit')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (nameCtl.text.trim().isEmpty || symbolCtl.text.trim().isEmpty) {
      _showWarning('Unit name and symbol are required!');
      return;
    }
    try {
      await ApiClient.instance.dio.put('/admin/updateUnit/${unit['id']}', data: {
        'name': nameCtl.text.trim(),
        'symbol': symbolCtl.text.trim(),
        'conversionValue': convValueCtl.text.trim().isEmpty ? null : int.tryParse(convValueCtl.text.trim()),
        'conversionUnit': convUnitCtl.text.trim().isEmpty ? null : convUnitCtl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit updated successfully!')));
      }
      _fetchUnits();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _showError(status == 403
          ? '${e.response?.data ?? 'Access Denied!'}'
          : status == 404
              ? 'Unit not found or is a Default Unit!'
              : status == 409
                  ? 'Unit name already exists!'
                  : 'Failed to update unit!');
    }
  }

  Future<void> _handleDeleteUnit(Map<String, dynamic> unit) async {
    if (_isDefault(unit)) {
      _showWarning('This is a default unit and cannot be deleted!');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text('Are you sure you want to delete "${unit['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE03535)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await ApiClient.instance.dio.delete('/admin/deleteUnit/${unit['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res.data ?? 'Unit deleted successfully!'}')));
      }
      if (_selectedUnit?['id'] == unit['id']) setState(() => _selectedUnit = null);
      _fetchUnits();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _showError(status == 403
          ? '${e.response?.data ?? 'Unit is used by items, cannot delete!'}'
          : status == 404
              ? 'Unit not found!'
              : 'Failed to delete unit!');
    }
  }

  void _showWarning(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Warning'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUnits => _units
      .where((u) => '${u['name'] ?? ''}'.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Unit'),
            bottom: const ItemsSectionTabBar(active: 'unit'),
            actions: [
              if (_isAdmin)
                IconButton(icon: const Icon(Icons.add), onPressed: _handleAddUnit, tooltip: 'Add Unit'),
            ],
          ),
          body: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: _unitListPanel()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _conversionPanel()),
                  ],
                )
              : (_selectedUnit == null
                  ? _unitListPanel()
                  : Column(
                      children: [
                        ListTile(
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setState(() => _selectedUnit = null),
                          ),
                          title: Text('${_selectedUnit!['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: _conversionPanel()),
                      ],
                    )),
        );
      },
    );
  }

  Widget _unitListPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search...', isDense: true),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUnits.isEmpty
                  ? const Center(child: Text('No units found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filteredUnits.length,
                      itemBuilder: (context, i) {
                        final unit = _filteredUnits[i];
                        final active = _selectedUnit?['id'] == unit['id'];
                        return ListTile(
                          selected: active,
                          title: Text('${unit['name'] ?? '—'} (${unit['symbol'] ?? ''})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                child: Text('${unit['itemCount'] ?? 0}', style: const TextStyle(fontSize: 10)),
                              ),
                              if (_isAdmin)
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _handleEditUnit(unit);
                                    if (v == 'delete') _handleDeleteUnit(unit);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                            ],
                          ),
                          onTap: () => _selectUnit(unit),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _conversionPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Units', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          if (_selectedUnit == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Select a unit to view conversion', style: TextStyle(color: Colors.grey))))
          else if (_selectedUnit!['conversionValue'] == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No conversion available', style: TextStyle(color: Colors.grey))))
          else
            Card(
              child: ListTile(
                title: Text(
                  '1 ${_selectedUnit!['name']} = ${_selectedUnit!['conversionValue']} ${_selectedUnit!['conversionUnit'] ?? ''}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
