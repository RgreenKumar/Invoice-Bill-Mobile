import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

void main() {
  runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Invoice UI",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xffEEF2F5),
      ),
      home: const DashboardScreen(),
    );
  }
}

class SupplierScreen extends StatelessWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),

          Expanded(
            child: Column(
              children: [
                const TopBar(),

                Expanded(
                  child: Row(
                    children: [
                      SupplierList(),

                      VerticalDivider(width: 1),

                      Expanded(child: SupplierDetails()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  Widget menu(IconData icon, String title, {bool selected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xff243B53) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xff17384C),
      child: Column(
        children: [
          const SizedBox(height: 15),

          Row(
            children: const [
              SizedBox(width: 20),
              Icon(Icons.receipt_long, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Invoice",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          menu(Icons.dashboard_outlined, "Dashboard"),

          menu(Icons.inventory_2_outlined, "Items"),

          menu(Icons.groups, "Parties/Customer", selected: true),

          const Padding(
            padding: EdgeInsets.only(left: 40),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.local_shipping, color: Colors.white),
                  title: Text(
                    "Suppliers",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text(
                    "Customers",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          menu(Icons.point_of_sale, "Sales"),

          menu(Icons.settings, "Settings"),

          menu(Icons.payment, "Payments"),

          menu(Icons.backup, "Manage Backups"),

          menu(Icons.restore, "Restore Data"),

          menu(Icons.business, "My Company"),

          const Spacer(),

          Container(
            color: Colors.black12,
            height: 40,
            alignment: Alignment.center,
            child: const Text(
              "© 2024 All rights reserved",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,

      color: const Color(0xff17384C),

      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Row(
        children: [
          const Icon(Icons.menu, color: Colors.white),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_brightness, color: Colors.white),
          ),

          CircleAvatar(
            backgroundColor: Colors.green,
            child: const Text("J", style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(width: 10),

          const Text("Janani", style: TextStyle(color: Colors.white)),

          const SizedBox(width: 10),

          const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ],
      ),
    );
  }
}

class SupplierList extends StatelessWidget {
  const SupplierList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,

      color: Colors.white,

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  "Suppliers",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blueGrey,
                  child: const Text("0", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search supplier name...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    "SUPPLIER NAME",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Text("BALANCE", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                "No suppliers found",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierDetails extends StatelessWidget {
  const SupplierDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,

      child: Column(
        children: [
          Container(
            height: 60,

            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Row(
              children: [
                const Text("Suppliers", style: TextStyle(fontSize: 24)),

                const Spacer(),

                DropdownButton<String>(
                  value: "All",
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All")),
                  ],
                  onChanged: (_) {},
                ),

                const SizedBox(width: 15),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),

                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddSupplierDialog(),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Supplier",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.handshake_outlined, size: 90, color: Colors.grey),

                  SizedBox(height: 20),

                  Text(
                    "Select a supplier to view details",
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddSupplierDialog extends StatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(40),

      child: Container(
        width: 1200,

        height: 650,

        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  "Add Supplier",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(child: textField("Supplier Name *")),

                const SizedBox(width: 20),

                Expanded(child: textField("GSTIN *")),

                const SizedBox(width: 20),

                Expanded(child: textField("Phone Number")),
              ],
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: "GST & Address"),

                  Tab(text: "Credit & Balance"),

                  Tab(text: "Additional Fields"),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: tabController,

                children: [gstAddressTab(), creditTab(), additionalTab()],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,

              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text("Cancel"),
                ),

                const SizedBox(width: 15),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff17384C),
                  ),

                  onPressed: () {},

                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget gstAddressTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),

      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                dropdown("GST Type", [
                  "Unregistered/Consumer",
                  "Registered Business",
                ]),

                const SizedBox(height: 20),

                dropdown("State", ["Select State"]),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: textField("Email ID")),

                    const SizedBox(width: 10),

                    SizedBox(
                      height: 48,

                      child: ElevatedButton(
                        onPressed: () {},

                        child: const Text("Send OTP"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Billing Address",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: TextField(
                    maxLines: null,

                    expands: true,

                    decoration: const InputDecoration(
                      hintText: "Billing Address",

                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    const Text(
                      "Shipping Address",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed: () {},

                      child: const Text("+ Enable Shipping Address"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: TextField(
                    maxLines: null,

                    expands: true,

                    decoration: const InputDecoration(
                      hintText: "Shipping Address",

                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget creditTab() {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: textField("Opening Balance")),

              const SizedBox(width: 20),

              Expanded(child: textField("Credit Limit")),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: textField("Credit Days")),

              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget additionalTab() {
    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: textField("Contact Person")),

              const SizedBox(width: 20),

              Expanded(child: textField("Website")),
            ],
          ),

          const SizedBox(height: 20),

          textField("Notes"),
        ],
      ),
    );
  }

  Widget textField(String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,

        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget dropdown(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      value: items.first,

      decoration: InputDecoration(
        labelText: label,

        border: const OutlineInputBorder(),
      ),

      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),

      onChanged: (_) {},
    );
  }
}
