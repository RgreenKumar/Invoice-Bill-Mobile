import 'package:flutter/material.dart';
import '../utils/app_data.dart';

class SupplierScreen extends StatelessWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Row(
        children: [
          SupplierList(),
          VerticalDivider(width: 1),
          Expanded(child: SupplierDetails()),
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
                ValueListenableBuilder<List<SupplierRecord>>(
                  valueListenable: suppliersNotifier,
                  builder: (context, suppliers, _) {
                    return CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        "${suppliers.length}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
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
          Expanded(
            child: ValueListenableBuilder<List<SupplierRecord>>(
              valueListenable: suppliersNotifier,
              builder: (context, suppliers, _) {
                if (suppliers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No suppliers found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];

                    return ListTile(
                      title: Text(supplier.name),
                      subtitle: Text(supplier.phone),
                      trailing: Text(
                        "₹ ${supplier.balance.toStringAsFixed(0)}",
                      ),
                    );
                  },
                );
              },
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
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                          onPressed: () async {
                            final supplier = await showDialog<SupplierRecord>(
                              context: context,
                              builder: (_) => const AddSupplierDialog(),
                            );
                            if (supplier != null) {
                              addSupplier(supplier);
                            }
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
  final _nameController = TextEditingController();
  final _gstController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  String _selectedState = indianStates.first;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _textField("Supplier Name *", _nameController)),
                const SizedBox(width: 20),
                Expanded(child: _textField("GSTIN *", _gstController)),
                const SizedBox(width: 20),
                Expanded(child: _textField("Phone Number", _phoneController)),
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
                children: [_gstAddressTab(), _creditTab(), _additionalTab()],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff17384C),
                  ),
                  onPressed: _saveSupplier,
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

  Widget _gstAddressTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _dropdown("GST Type", [
                  "Unregistered/Consumer",
                  "Registered Business",
                ]),
                const SizedBox(height: 20),
                _dropdown("State", indianStates),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _textField("Email ID", _emailController)),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _showOtpSentDialog,
                        child: const Text("Send OTP"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _addressField("Billing Address")),
          const SizedBox(width: 20),
          Expanded(child: _addressField("Shipping Address")),
        ],
      ),
    );
  }

  Widget _creditTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _textField("Opening Balance", _openingBalanceController),
              ),
              const SizedBox(width: 20),
              Expanded(child: _textField("Credit Limit")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _textField("Credit Days")),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _additionalTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _textField("Contact Person")),
              const SizedBox(width: 20),
              Expanded(child: _textField("Website")),
            ],
          ),
          const SizedBox(height: 20),
          _textField("Notes"),
        ],
      ),
    );
  }

  Widget _addressField(String label) {
    return TextField(
      expands: true,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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

  void _saveSupplier() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Supplier name is required")),
      );
      return;
    }

    Navigator.pop(
      context,
      SupplierRecord(
        name: name,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gst: _gstController.text.trim(),
        state: _selectedState,
        balance: parseAmount(_openingBalanceController.text),
      ),
    );
  }

  Widget _textField(String label, [TextEditingController? controller]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      value: items.first,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (label == "State" && value != null) {
          _selectedState = value;
        }
      },
    );
  }
}
