import 'package:flutter/material.dart';
import '../utils/app_data.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final List<Map<String, dynamic>> items = [
    {"item": "", "qty": 1, "price": 0, "gst": 18, "amount": 0},
  ];
  final _invoiceNoController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
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
    _invoiceNoController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F5),

      appBar: AppBar(
        title: const Text("Create Sales Invoice"),
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
                //------------------------------------
                // Customer Details
                //------------------------------------
                Row(
                  children: [
                    Expanded(child: customerDropdown()),

                    const SizedBox(width: 20),

                    Expanded(
                      child: textField("Invoice No", _invoiceNoController),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: textField("Invoice Date", _invoiceDateController),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: textField("Due Date", _dueDateController)),

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

                invoiceTable(),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: addItem,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Item"),
                  ),
                ),

                const SizedBox(height: 30),

                totalsSection(),

                const SizedBox(height: 30),

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

                    const SizedBox(width: 15),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff17384C),
                      ),
                      onPressed: saveInvoice,
                      child: const Text(
                        "Save Invoice",
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget invoiceTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),

      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xffF5F5F5)),

          children: [
            TableHeading("Item"),

            TableHeading("Qty"),

            TableHeading("Price"),

            TableHeading("GST"),

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

              Padding(
                padding: const EdgeInsets.all(12),

                child: Text("${e['amount']}"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget totalsSection() {
    return Align(
      alignment: Alignment.centerRight,

      child: SizedBox(
        width: 350,

        child: Column(
          children: [
            totalRow("Subtotal", "₹ 0"),

            totalRow("GST", "₹ 0"),

            totalRow("Discount", "₹ 0"),

            const Divider(),

            totalRow("Grand Total", "₹ 0", bold: true),
          ],
        ),
      ),
    );
  }

  void addItem() {
    setState(() {
      items.add({"item": "", "qty": 1, "price": 0, "gst": 18, "amount": 0});
    });
  }

  void saveInvoice() {
    final invoiceNo = _invoiceNoController.text.trim();
    final customer = _selectedCustomer;
    if (invoiceNo.isEmpty || customer == null || customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice no and customer are required")),
      );
      return;
    }

    Navigator.pop(
      context,
      InvoiceRecord(
        invoiceNo: invoiceNo,
        customer: customer,
        date: _invoiceDateController.text.trim(),
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

class TableHeading extends StatelessWidget {
  final String text;

  const TableHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),

      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

Widget tableField() {
  return Padding(
    padding: const EdgeInsets.all(8),

    child: TextField(
      decoration: const InputDecoration(border: InputBorder.none),
    ),
  );
}
