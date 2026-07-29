import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';

/// Port of `src/UserSettings/Itemsettings.js`, routed at
/// `/settings/Items`.
///
/// Preserves:
///  - GET /settings/item/get on load, GET /getUnits (for the "Default
///    Unit" picker)
///  - POST /settings/item/save on save, then pushes into
///    GlobalStateProvider so AddItemScreen picks up the new toggles
///  - All fields from the original: enable item / stock maintenance /
///    low-stock dialog / units / default unit / category / description /
///    item-wise tax & discount / quantity decimal places / wholesale
///    price / MRP / tax-based-on-MRP / exp & mfg dates (+ format) /
///    model no / size
///
/// MOBILE-FIRST REWRITE: the original laid this out as 2 side-by-side
/// desktop columns ("Item Settings" | "Additional Item Fields"). Rebuilt
/// as a single scrollable column with section headers instead, matching
/// every other settings screen in this app.
class ItemSettingsScreen extends StatefulWidget {
  const ItemSettingsScreen({super.key});

  @override
  State<ItemSettingsScreen> createState() => _ItemSettingsScreenState();
}

class _ItemSettingsScreenState extends State<ItemSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;
  List<Map<String, dynamic>> _units = [];

  Map<String, dynamic> _settings = {
    'enableItem': true,
    'stockMaintenance': true,
    'showLowStockDialog': true,
    'itemsUnit': true,
    'defaultUnit': null,
    'defaultUnitName': null,
    'itemCategory': true,
    'description': false,
    'itemWiseTax': true,
    'itemWiseDiscount': true,
    'quantityDecimalPlaces': 2,
    'wholesalePrice': true,
    'mrp': false,
    'calculateTaxBasedOnMrp': false,
    'expDate': true,
    'expDateFormat': 'mm/yy',
    'mfgDate': true,
    'mfgDateFormat': 'dd/mm/yy',
    'modelNo': false,
    'size': false,
  };

  bool get _canCreate => getPermission(null, 'canCreate');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/settings/item/get');
      if (res.data is Map) {
        setState(() => _settings = {..._settings, ...Map<String, dynamic>.from(res.data as Map)});
      }
    } catch (e) {
      debugPrint('Failed to load item settings: $e');
    }
    try {
      final res = await ApiClient.instance.dio.get('/getUnits');
      if (res.data is List) {
        setState(() => _units = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (e) {
      debugPrint('Failed to load units: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDefaultUnit() async {
    if (_settings['defaultUnit'] != null) {
      setState(() {
        _settings['defaultUnit'] = null;
        _settings['defaultUnitName'] = null;
      });
      return;
    }
    if (_units.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No units found. Please add units first.')));
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('Select Default Unit'),
        children: _units
            .map((u) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogCtx, u),
                  child: Text('${u['name'] ?? ''}'),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _settings['defaultUnit'] = selected['id'];
        _settings['defaultUnitName'] = selected['name'];
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.instance.dio.post('/settings/item/save', data: _settings);
      if (mounted) {
        context.read<GlobalStateProvider>().setGlobalItemSettings(_settings);
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved!'),
            content: const Text('Item Settings saved successfully.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) setState(() => _isEdit = false);
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save item settings')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Item Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20),
                _toggle('Enable Item', 'enableItem'),
                _toggle('Stock Maintenance', 'stockMaintenance'),
                _toggle('Show Low Stock Dialog', 'showLowStockDialog'),
                _toggle('Items Unit', 'itemsUnit'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_settings['defaultUnit'] != null
                      ? 'Default Unit (${_settings['defaultUnitName']})'
                      : 'Default Unit'),
                  value: _settings['defaultUnit'] != null,
                  onChanged: _isEdit ? (_) => _pickDefaultUnit() : null,
                ),
                _toggle('Item Category', 'itemCategory'),
                _toggle('Description', 'description'),
                _toggle('Item wise Tax', 'itemWiseTax'),
                _toggle('Item wise Discount', 'itemWiseDiscount'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Quantity (upto Decimal Places)')),
                      IconButton(
                        onPressed: _isEdit
                            ? () => setState(() => _settings['quantityDecimalPlaces'] =
                                ((_settings['quantityDecimalPlaces'] as int? ?? 0) - 1).clamp(0, 9))
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${_settings['quantityDecimalPlaces'] ?? 2}'),
                      IconButton(
                        onPressed: _isEdit
                            ? () => setState(() => _settings['quantityDecimalPlaces'] =
                                ((_settings['quantityDecimalPlaces'] as int? ?? 0) + 1).clamp(0, 9))
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                _toggle('Wholesale Price', 'wholesalePrice'),
                const SizedBox(height: 12),
                const Text('Additional Item Fields', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20),
                _toggle('MRP', 'mrp'),
                _toggle('Calculate Tax based on MRP', 'calculateTaxBasedOnMrp'),
                _toggleWithFormat('Exp Date', 'expDate', 'expDateFormat'),
                _toggleWithFormat('Mfg Date', 'mfgDate', 'mfgDateFormat'),
                _toggle('Model No.', 'modelNo'),
                _toggle('Size', 'size'),
                const SizedBox(height: 16),
                if (_canCreate)
                  _isEdit
                      ? FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save'),
                        )
                      : FilledButton.tonal(
                          onPressed: () => setState(() => _isEdit = true),
                          child: const Text('Edit'),
                        ),
              ],
            ),
    );
  }

  Widget _toggle(String label, String key) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: _settings[key] == true,
      onChanged: _isEdit ? (v) => setState(() => _settings[key] = v) : null,
    );
  }

  Widget _toggleWithFormat(String label, String key, String formatKey) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            value: _settings[key] == true,
            onChanged: _isEdit ? (v) => setState(() => _settings[key] = v) : null,
          ),
        ),
        DropdownButton<String>(
          value: _settings[formatKey] as String? ?? 'mm/yy',
          items: const [
            DropdownMenuItem(value: 'mm/yy', child: Text('mm/yy')),
            DropdownMenuItem(value: 'dd/mm/yy', child: Text('dd/mm/yy')),
            DropdownMenuItem(value: 'mm/dd/yy', child: Text('mm/dd/yy')),
          ],
          onChanged: _isEdit ? (v) => setState(() => _settings[formatKey] = v) : null,
        ),
      ],
    );
  }
}
