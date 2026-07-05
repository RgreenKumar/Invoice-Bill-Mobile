import 'package:flutter/material.dart';
import '../utils/app_data.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _gstController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  String _selectedState = indianStates.first;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _gstController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(30),

      child: Container(
        width: 1200,

        height: 670,

        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            //----------------------------------------
            // Header
            //----------------------------------------
            Row(
              children: [
                const Text(
                  "Add Customer",

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

            const SizedBox(height: 25),

            //----------------------------------------
            // Top Fields
            //----------------------------------------
            Row(
              children: [
                Expanded(
                  child: customField("Customer Name *", _nameController),
                ),

                const SizedBox(width: 20),

                Expanded(child: customField("GSTIN", _gstController)),

                const SizedBox(width: 20),

                Expanded(child: customField("Phone Number", _phoneController)),
              ],
            ),

            const SizedBox(height: 20),

            //----------------------------------------
            // Tabs
            //----------------------------------------
            Align(
              alignment: Alignment.centerLeft,

              child: TabBar(
                controller: _tabController,

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
                controller: _tabController,

                children: [gstTab(), creditTab(), additionalTab()],
              ),
            ),

            //----------------------------------------
            // Bottom Buttons
            //----------------------------------------
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

                  onPressed: _saveCustomer,

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

  Widget gstTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),

      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                customDropdown("GST Type", ["Unregistered", "Registered"]),

                const SizedBox(height: 20),

                customDropdown("State", indianStates),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: customField("Email", _emailController)),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: _showOtpSentDialog,

                      child: const Text("Send OTP"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: TextField(
              expands: true,

              maxLines: null,

              decoration: const InputDecoration(
                labelText: "Billing Address",

                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: TextField(
              expands: true,

              maxLines: null,

              decoration: const InputDecoration(
                labelText: "Shipping Address",

                border: OutlineInputBorder(),
              ),
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
              Expanded(
                child: customField(
                  "Opening Balance",
                  _openingBalanceController,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(child: customField("Credit Limit")),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: customField("Credit Days")),

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
              Expanded(child: customField("Contact Person")),

              const SizedBox(width: 20),

              Expanded(child: customField("Website")),
            ],
          ),

          const SizedBox(height: 20),

          customField("Notes"),
        ],
      ),
    );
  }

  void _showOtpSentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text("sent successfuly"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _saveCustomer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer name is required")),
      );
      return;
    }

    Navigator.pop(
      context,
      CustomerRecord(
        name: name,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gst: _gstController.text.trim(),
        state: _selectedState,
        balance: parseAmount(_openingBalanceController.text),
      ),
    );
  }

  Widget customField(String label, [TextEditingController? controller]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,

        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget customDropdown(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      value: items.first,

      decoration: InputDecoration(
        labelText: label,

        border: const OutlineInputBorder(),
      ),

      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),

      onChanged: (value) {
        if (label == "State" && value != null) {
          _selectedState = value;
        }
      },
    );
  }
}
