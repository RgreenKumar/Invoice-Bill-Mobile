import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';

/// Port of `src/UserSettings/TaxesGST.js`, routed at
/// `/settings/taxes&gstpage`.
///
/// Preserves:
///  - Reads gstSettings from GlobalStateProvider (already loaded once at
///    app startup via GET /settings/gst/get - mirrors GlobalStateContext)
///  - POST /settings/gst/save on save, then updates the provider so every
///    other screen (invoice form, item form) sees the new toggles
///    immediately
class TaxesGstScreen extends StatefulWidget {
  const TaxesGstScreen({super.key});

  @override
  State<TaxesGstScreen> createState() => _TaxesGstScreenState();
}

class _TaxesGstScreenState extends State<TaxesGstScreen> {
  bool _isEdit = false;
  bool _saving = false;
  late Map<String, dynamic> _gstSettings;

  static const _checkboxItems = [
    ['enableGST', 'Enable GST'],
    ['enableHSN', 'Enable HSN/SAC Code'],
    ['additionalCess', 'Additional Cess On Item'],
    ['enablePlaceOfSupply', 'Enable Place of Supply'],
  ];

  bool get _canCreate => getPermission(null, 'canCreate');

  @override
  void initState() {
    super.initState();
    _gstSettings = Map<String, dynamic>.from(context.read<GlobalStateProvider>().gstSettings);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.instance.dio.post('/settings/gst/save', data: _gstSettings);
      if (mounted) {
        context.read<GlobalStateProvider>().setGstSettings(_gstSettings);
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved!'),
            content: const Text('GST Settings saved successfully.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) setState(() => _isEdit = false);
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save GST settings')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxes & GST')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('GST Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 24),
                  for (final item in _checkboxItems)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item[1]),
                      value: _gstSettings[item[0]] == true,
                      onChanged: _isEdit ? (v) => setState(() => _gstSettings[item[0]] = v) : null,
                    ),
                  if (_canCreate) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _isEdit
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
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
