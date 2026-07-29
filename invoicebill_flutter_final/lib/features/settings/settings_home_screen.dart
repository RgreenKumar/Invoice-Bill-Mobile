import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';
import 'site_settings_screen.dart';

/// Port of `src/UserSettings/SettingsComponent.js`, routed at
/// `/settings/viewsettings` (React's "Settings" landing page - what the
/// sidebar's "Settings" link actually opens).
///
/// Preserves:
///  - GET /settings/general/get on load, POST /settings/general/save on save
///  - 4 general toggles + amount decimal places, view/edit gated by
///    getPermission(null, ...) (MODULES.SETTINGS is undefined in the
///    original app, so only ADMIN/SYSADMIN ever get canCreate/canEdit here)
///  - Embeds Sitesettings (VPS-profile only) via SiteSettingsScreen link
///
/// MOBILE-FIRST REWRITE: the original embedded a fly-out "Site Settings"
/// dropdown plus the full Sitesettings form inline on the same page. On
/// mobile that's replaced with a simple settings menu (cards/list tiles)
/// linking to each settings area - Mail, Footer, Roles, Weightage,
/// Taxes & GST, Item Settings, Manage Users, and Site Settings.
class SettingsHomeScreen extends StatefulWidget {
  const SettingsHomeScreen({super.key});

  @override
  State<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends State<SettingsHomeScreen> {
  bool _isEdit = false;
  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic> _form = {
    'amountDecimalPlaces': 2,
    'gstinNumber': true,
    'estimateQuotation': true,
    'salesInvoiceOrder': true,
    'otpservice': true,
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
      final res = await ApiClient.instance.dio.get('/settings/general/get');
      if (res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        setState(() {
          _form = {
            'amountDecimalPlaces': data['amountDecimalPlaces'] ?? 2,
            'gstinNumber': data['gstinNumber'] ?? true,
            'estimateQuotation': data['estimateQuotation'] ?? true,
            'salesInvoiceOrder': data['salesInvoiceOrder'] ?? true,
            'otpservice': data['otpservice'] ?? true,
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.instance.dio.post('/settings/general/save', data: _form);
      if (mounted) {
        context.read<GlobalStateProvider>().setGeneralSettings(_form);
        await showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Saved!'),
            content: const Text('Settings saved successfully.'),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('OK'))],
          ),
        );
        if (mounted) setState(() => _isEdit = false);
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save settings')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = context.watch<GlobalStateProvider>().activeProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('General Settings', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Amount (upto Decimal Places)'),
                            ),
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                enabled: _isEdit,
                                initialValue: '${_form['amountDecimalPlaces']}',
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                onChanged: (v) => _form['amountDecimalPlaces'] = int.tryParse(v) ?? 2,
                              ),
                            ),
                          ],
                        ),
                        _toggle('GSTIN Number', 'gstinNumber'),
                        _toggle('Estimate/Quotation', 'estimateQuotation'),
                        _toggle('Sales Invoice Order', 'salesInvoiceOrder'),
                        _toggle('OTP Service', 'otpservice'),
                        if (_canCreate) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _isEdit
                                ? FilledButton(
                                    onPressed: _saving ? null : _save,
                                    child: _saving
                                        ? const SizedBox(
                                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
                const SizedBox(height: 24),
                Text('More Settings', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _navTile(context, Icons.mail_outline, 'Mail Settings', '/settings/mailSettings'),
                      const Divider(height: 1),
                      _navTile(context, Icons.article_outlined, 'Footer Details', '/settings/footer'),
                      const Divider(height: 1),
                      _navTile(context, Icons.badge_outlined, 'Role Display Names', '/settings/displayname'),
                      const Divider(height: 1),
                      _navTile(context, Icons.percent, 'Grade Weightage', '/settings/Weightage'),
                      const Divider(height: 1),
                      _navTile(context, Icons.receipt_long_outlined, 'Taxes & GST', '/settings/taxes&gstpage'),
                      const Divider(height: 1),
                      _navTile(context, Icons.inventory_2_outlined, 'Item Settings', '/settings/Items'),
                      const Divider(height: 1),
                      _navTile(context, Icons.people_outline, 'Manage Users', '/settings/users'),
                      if (activeProfile == 'VPS') ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Site Settings'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SiteSettingsScreen()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toggle(String label, String key) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: _form[key] == true,
      onChanged: _isEdit ? (v) => setState(() => _form[key] = v) : null,
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title, String path) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(path),
    );
  }
}
