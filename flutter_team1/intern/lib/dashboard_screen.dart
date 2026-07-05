import 'package:flutter/material.dart';
import 'screens/supplier_screen.dart';
import 'screens/customer_screen.dart';
import 'screens/sales_invoice_screen.dart';
import 'screens/estimate_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    SupplierScreen(),
    CustomerScreen(),
    SalesInvoiceScreen(),
    EstimateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            backgroundColor: const Color(0xff17384C),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(color: Colors.white),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping),
                label: Text("Suppliers"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text("Customers"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                label: Text("Sales"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description),
                label: Text("Estimate"),
              ),
            ],
          ),

          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
