import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/global_state_provider.dart';
import '../../core/utils/permissions.dart';
import '../../theme/app_theme.dart';

/// Port of `src/Common Components/Sidebar.js`.
///
/// Preserves the original's role-gated menu trees exactly:
///   - ADMIN: full menu (Items, Parties/Customer, Sales, Settings,
///     Payments, Manage Backups [Activeprofile == "VPS" only],
///     Restore data [VPS only], My Company)
///   - SYSADMIN: Dashboard, Admins, Cashiers, Restore data
///   - CASHIER: same shape as ADMIN but every section/item is gated by
///     `getPermission(MODULE, "canView")`
///   - TRAINER and USER sidebars are commented out in the original
///     source (dead code) and are therefore intentionally NOT rendered
///     here either - preserving current behavior rather than "fixing" it.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthSnapshot.role;
    final state = context.watch<GlobalStateProvider>();
    final activeProfile = state.activeProfile;
    final generalSettings = state.generalSettings;
    final displayname = state.displayname;

    return Container(
      color: AppColors.darkStart,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (role == 'ADMIN')
                ..._adminMenu(context, activeProfile, generalSettings, displayname)
              else if (role == 'SYSADMIN')
                ..._sysAdminMenu(context)
              else if (role == 'CASHIER')
                ..._cashierMenu(context, generalSettings),
            ],
          ),
        ),
      ),
    );
  }

  // ── ADMIN ──
  List<Widget> _adminMenu(
    BuildContext context,
    String activeProfile,
    Map<String, dynamic> generalSettings,
    Map<String, dynamic> displayname,
  ) {
    final isVps = activeProfile == 'VPS';
    return [
      _navItem(context, Icons.home, 'Dashboard', '/admin/dashboard'),
      _navGroup(Icons.dashboard_customize, 'Items', [
        _subItem(context, 'Add Item', '/item/additem'),
        _subItem(context, 'View Item', '/dashboard/viewitem'),
      ]),
      _navGroup(Icons.people, 'Suppliers & Customers', [
        _subItem(context, (displayname['trainer_name'] as String?)?.isNotEmpty == true
            ? displayname['trainer_name'] : 'Suppliers', '/view/Trainer'),
        _subItem(context, (displayname['student_name'] as String?)?.isNotEmpty == true
            ? displayname['student_name'] : 'Customers', '/view/Students'),
      ]),
      _navGroup(Icons.show_chart, 'Sales', [
        if (generalSettings['salesInvoiceOrder'] == true)
          _subItem(context, 'Sale Invoices', '/view/salesinvoice'),
        if (generalSettings['estimateQuotation'] == true)
          _subItem(context, 'Estimate/Quotation', '/view/estimateinvoice'),
        _subItem(context, 'Invoice POS', '/view/POSform'),
      ]),
      _navGroup(Icons.settings, 'Settings', [
        _subItem(context, 'General', '/settings/viewsettings'),
        _subItem(context, 'Taxes & GST', '/settings/taxes&gstpage'),
        _subItem(context, 'Items', '/settings/Items'),
        _subItem(context, 'Manage Users', '/settings/users'),
      ]),
      _navGroup(Icons.credit_card, 'Payments', [
        _subItem(context, 'Payment Keys', '/payment/keys'),
        _subItem(context, 'Transactions', '/payment/transactionHitory'),
      ]),
      if (isVps)
        _navGroup(Icons.cached, 'Manage Backups', [
          _subItem(context, 'Drive keys', '/admin/driveCredentials'),
          _subItem(context, 'Schedule backup', '/admin/backup-shedule'),
        ]),
      if (isVps) _navItem(context, Icons.settings_backup_restore, 'Restore data', '/restore'),
      _navItem(context, Icons.business, 'My Company', '/admin/mycompany'),
    ];
  }

  // ── SYSADMIN ──
  List<Widget> _sysAdminMenu(BuildContext context) {
    return [
      _navItem(context, Icons.home, 'Dashboard', '/admin/dashboard'),
      _navItem(context, Icons.manage_accounts, 'Admins', '/viewAll/Admins'),
      _navItem(context, Icons.point_of_sale, 'Cashiers', '/viewAll/Cashiers'),
      _navItem(context, Icons.settings_backup_restore, 'Restore data', '/restore'),
    ];
  }

  // ── CASHIER (every entry gated by getPermission) ──
  List<Widget> _cashierMenu(BuildContext context, Map<String, dynamic> generalSettings) {
    final items = <Widget>[
      _navItem(context, Icons.home, 'Dashboard', '/admin/dashboard'),
    ];

    if (getPermission(Modules.addItem, 'canView') || getPermission(Modules.viewItem, 'canView')) {
      items.add(_navGroup(Icons.dashboard_customize, 'Items', [
        if (getPermission(Modules.addItem, 'canView')) _subItem(context, 'Add Item', '/item/additem'),
        if (getPermission(Modules.viewItem, 'canView')) _subItem(context, 'View Item', '/dashboard/viewitem'),
      ]));
    }

    if (getPermission(Modules.parties, 'canView') || getPermission(Modules.customer, 'canView')) {
      items.add(_navGroup(Icons.people, 'Suppliers & Customers', [
        if (getPermission(Modules.parties, 'canView')) _subItem(context, 'Suppliers', '/view/Trainer'),
        if (getPermission(Modules.customer, 'canView')) _subItem(context, 'Customers', '/view/Students'),
      ]));
    }

    final showSales = getPermission(Modules.saleInvoice, 'canView') ||
        getPermission(Modules.estimateQuotation, 'canView') ||
        getPermission(Modules.invoicePos, 'canView');
    if (showSales) {
      items.add(_navGroup(Icons.show_chart, 'Sales', [
        if (getPermission(Modules.saleInvoice, 'canView') && generalSettings['salesInvoiceOrder'] == true)
          _subItem(context, 'Sale Invoices', '/view/salesinvoice'),
        if (getPermission(Modules.estimateQuotation, 'canView') && generalSettings['estimateQuotation'] == true)
          _subItem(context, 'Estimate/Quotation', '/view/estimateinvoice'),
        if (getPermission(Modules.invoicePos, 'canView')) _subItem(context, 'Invoice POS', '/view/POSform'),
      ]));
    }

    // NOTE: MODULES.SETTINGS / MODULES.MY_COMPANY are undefined in the
    // original - so these two sections never render for CASHIER. See
    // Modules class doc comment. Intentionally omitted here to match.

    return items;
  }

  void _navigate(BuildContext context, String path) {
    Navigator.of(context).pop(); // close the drawer first
    context.go(path);
  }

  // ── shared row builders ──
  Widget _navItem(BuildContext context, IconData icon, String label, String path) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => _navigate(context, path),
    );
  }

  Widget _navGroup(IconData icon, String label, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        children: children,
      ),
    );
  }

  Widget _subItem(BuildContext context, String? label, String path) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ListTile(
        dense: true,
        title: Text(label ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        onTap: () => _navigate(context, path),
      ),
    );
  }
}
