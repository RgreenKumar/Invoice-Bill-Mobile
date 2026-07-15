import 'package:flutter/material.dart';
import '../app_feature_settings.dart';
import '../parties/screens/supplier_screen.dart';
import '../parties/screens/customer_screen.dart';
import '../parties/screens/sales_invoice_screen.dart';
import '../parties/screens/estimate_screen.dart';
import '../parties/utils/app_data.dart';
import '../items_settings/screens/main_layout.dart';
import '../company/business_details_page.dart';
import '../screens/auth_container.dart';

class AppDashboard extends StatefulWidget {
  const AppDashboard({super.key});

  @override
  State<AppDashboard> createState() => _AppDashboardState();
}

class _AppDashboardState extends State<AppDashboard> {
  String _currentView = 'dashboard'; // Current active view ID

  Widget _buildContent() {
    switch (_currentView) {
      case 'dashboard':
        return _DashboardHome(
          onOpenView: (viewId) => setState(() => _currentView = viewId),
        );
      case 'suppliers':
        return const SupplierScreen();
      case 'customers':
        return const CustomerScreen();
      case 'invoices':
        return const SalesInvoiceScreen();
      case 'estimates':
        return const EstimateScreen();
      case 'items_settings':
        return MainLayout(
          onNavigateDashboard: () => setState(() => _currentView = 'dashboard'),
          onNavigateParties: () => setState(() => _currentView = 'customers'),
        );
      case 'business_details':
        return const BusinessDetailsPage();
      default:
        return const Center(child: Text("Screen Not Found"));
    }
  }

  String _getViewTitle() {
    switch (_currentView) {
      case 'suppliers':
        return 'Supplier Management';
      case 'dashboard':
        return 'Dashboard';
      case 'customers':
        return 'Customer Management';
      case 'invoices':
        return 'Sales Invoices';
      case 'estimates':
        return 'Estimates & Quotations';
      case 'items_settings':
        return 'Items & App Settings';
      case 'business_details':
        return 'Business Configuration';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xff17384C);

    return Scaffold(
      body: Row(
        children: [
          // Navigation Sidebar
          Container(
            width: 260,
            color: themeColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Invoice Bill Mobile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sidebar Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _sidebarItem(
                        icon: Icons.dashboard_outlined,
                        title: "Dashboard",
                        viewId: "dashboard",
                      ),
                      _sidebarItem(
                        icon: Icons.handshake,
                        title: "Suppliers",
                        viewId: "suppliers",
                      ),
                      _sidebarItem(
                        icon: Icons.people,
                        title: "Customers",
                        viewId: "customers",
                      ),
                      _sidebarItem(
                        icon: Icons.receipt_long,
                        title: "Sales Invoices",
                        viewId: "invoices",
                      ),
                      _sidebarItem(
                        icon: Icons.description,
                        title: "Estimates",
                        viewId: "estimates",
                      ),
                      _sidebarItem(
                        icon: Icons.inventory_2,
                        title: "Items & Settings",
                        viewId: "items_settings",
                      ),
                      _sidebarItem(
                        icon: Icons.business,
                        title: "Business Details",
                        viewId: "business_details",
                      ),
                    ],
                  ),
                ),

                // Divider and Logout Option
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthContainer()),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main View Pane
          Expanded(
            child: Container(
              color: const Color(0xffEEF2F5),
              child: Column(
                children: [
                  // App Bar / Top Header Panel
                  Container(
                    height: 70,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          _getViewTitle(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                        const Spacer(),
                        const Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: themeColor,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Enterprise User",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                  // Render Content
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    required String viewId,
  }) {
    final bool isSelected = _currentView == viewId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white24 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _currentView = viewId;
          });
        },
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final ValueChanged<String> onOpenView;

  const _DashboardHome({required this.onOpenView});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppFeatureSettings>(
      valueListenable: appFeatureSettings,
      builder: (context, settings, _) {
        return Container(
          color: const Color(0xffEEF2F5),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statCard(
                    icon: Icons.people,
                    title: 'Customers',
                    value: '${customersNotifier.value.length}',
                    onTap: () => onOpenView('customers'),
                  ),
                  _statCard(
                    icon: Icons.handshake,
                    title: 'Suppliers',
                    value: '${suppliersNotifier.value.length}',
                    onTap: () => onOpenView('suppliers'),
                  ),
                  _statCard(
                    icon: Icons.receipt_long,
                    title: 'Invoices',
                    value: '${invoicesNotifier.value.length}',
                    onTap: () => onOpenView('invoices'),
                  ),
                  _statCard(
                    icon: Icons.description,
                    title: 'Estimates',
                    value: '${estimatesNotifier.value.length}',
                    onTap: () => onOpenView('estimates'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _quickActions(context, settings)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _enabledFeatures(settings)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 210,
      height: 112,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(
                    0xff17384C,
                  ).withValues(alpha: .1),
                  child: Icon(icon, color: const Color(0xff17384C)),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(title, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, AppFeatureSettings settings) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton(
                  Icons.person_add,
                  'Customers',
                  () => onOpenView('customers'),
                ),
                _actionButton(
                  Icons.add_business,
                  'Suppliers',
                  () => onOpenView('suppliers'),
                ),
                _actionButton(
                  Icons.receipt,
                  'Invoices',
                  () => onOpenView('invoices'),
                ),
                _actionButton(
                  Icons.inventory_2,
                  'Items',
                  settings.enableItems
                      ? () => onOpenView('items_settings')
                      : null,
                ),
                _actionButton(
                  Icons.settings,
                  'Settings',
                  () => onOpenView('items_settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff17384C),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _enabledFeatures(AppFeatureSettings settings) {
    final rows = [
      ('Items module', settings.enableItems),
      ('GST', settings.enableGst),
      ('HSN/SAC code', settings.enableGst && settings.enableHsn),
      ('Item discount', settings.itemWiseDiscount),
      ('Stock maintenance', settings.stockMaintenance),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enabled Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  row.$2 ? Icons.check_circle : Icons.cancel,
                  color: row.$2 ? Colors.green : Colors.grey,
                ),
                title: Text(row.$1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
