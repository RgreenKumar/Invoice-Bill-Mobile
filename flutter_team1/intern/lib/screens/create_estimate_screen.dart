import 'package:flutter/material.dart';
import '../utils/app_data.dart';

class CreateEstimateScreen extends StatefulWidget {
  const CreateEstimateScreen({super.key});

  @override
  State<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends State<CreateEstimateScreen> {
  List<Map<String, dynamic>> items = [
    {"item": "", "qty": 1, "rate": 0, "gst": 18, "discount": 0, "amount": 0},
  ];
  final _estimateNoController = TextEditingController();
  final _estimateDateController = TextEditingController();
  final _validUntilController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    final customers = customersNotifier.value;
    if (customers.isNotEmpty) {
      _selectedCustomer = customers.first.name;
    }
  }

  @override
  void dispose() {
    _estimateNoController.dispose();
    _estimateDateController.dispose();
    _validUntilController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void addItem() {
    setState(() {
      items.add({
        "item": "",
        "qty": 1,
        "rate": 0,
        "gst": 18,
        "discount": 0,
        "amount": 0,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F5),

      appBar: AppBar(
        title: const Text("Create Estimate / Quotation"),
        backgroundColor: const Color(0xff17384C),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// Customer Details
                Row(
                  children: [
                    Expanded(child: customerDropdown()),

                    const SizedBox(width: 20),

                    Expanded(
                      child: textField("Estimate No", _estimateNoController),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: textField(
                        "Estimate Date",
                        _estimateDateController,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: textField("Valid Until", _validUntilController),
                    ),

                    const SizedBox(width: 20),

                    Expanded(child: textField("Amount", _amountController)),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Items",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                estimateTable(),

                const SizedBox(height: 15),

                ElevatedButton.icon(
                  onPressed: addItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Item"),
                ),

                const SizedBox(height: 30),

                totals(),

                const SizedBox(height: 25),

                textField("Terms & Conditions"),

                const SizedBox(height: 20),

                textField("Notes"),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: saveEstimate,
                      child: const Text("Save"),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Print"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget estimateTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xffF5F5F5)),
          children: [
            TableHeading("Item"),
            TableHeading("Qty"),
            TableHeading("Rate"),
            TableHeading("GST"),
            TableHeading("Discount"),
            TableHeading("Amount"),
          ],
        ),

        ...items.map(
          (e) => TableRow(
            children: [
              tableField(),
              tableField(),
              tableField(),
              tableField(),
              tableField(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text("${e["amount"]}"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget totals() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 350,
        child: Column(
          children: [
            totalRow("Subtotal", "₹0"),

            totalRow("GST", "₹0"),

            totalRow("Discount", "₹0"),

            const Divider(),

            totalRow("Grand Total", "₹0", bold: true),
          ],
        ),
      ),
    );
  }

  void saveEstimate() {
    final estimateNo = _estimateNoController.text.trim();
    final customer = _selectedCustomer;
    if (estimateNo.isEmpty || customer == null || customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Estimate no and customer are required")),
      );
      return;
    }

    Navigator.pop(
      context,
      EstimateRecord(
        number: estimateNo,
        customer: customer,
        date: _estimateDateController.text.trim(),
        amount: parseAmount(_amountController.text),
        status: "Pending",
      ),
    );
  }

  Widget customerDropdown() {
    final customers = customersNotifier.value.map((e) => e.name).toList();

    return DropdownButtonFormField<String>(
      value: _selectedCustomer,
      decoration: const InputDecoration(
        labelText: "Customer",
        border: OutlineInputBorder(),
      ),
      items: customers
          .map((name) => DropdownMenuItem(value: name, child: Text(name)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCustomer = value;
        });
      },
    );
  }
}

Widget textField(String label, [TextEditingController? controller]) {
  return TextField(
    controller: controller,
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

class TableHeading extends StatelessWidget {
  final String title;

  const TableHeading(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

Widget tableField() {
  return const Padding(
    padding: EdgeInsets.all(8),
    child: TextField(decoration: InputDecoration(border: InputBorder.none)),
  );
}

Widget totalRow(String title, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
