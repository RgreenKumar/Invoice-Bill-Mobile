import 'package:flutter/material.dart';
import '../utils/app_data.dart';
import 'create_invoice_screen.dart';

class SalesInvoiceScreen extends StatelessWidget {
  const SalesInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F5),

      body: Column(
        children: [
          //-----------------------------------
          // Header
          //-----------------------------------
          Container(
            height: 65,

            color: Colors.white,

            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Row(
              children: [
                const Text(
                  "Sales Invoice",

                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                SizedBox(
                  width: 220,

                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search Invoice",

                      prefixIcon: const Icon(Icons.search),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),

                  onPressed: () async {
                    final invoice = await Navigator.push<InvoiceRecord>(
                      context,

                      MaterialPageRoute(
                        builder: (_) => const CreateInvoiceScreen(),
                      ),
                    );
                    if (invoice != null) {
                      addInvoice(invoice);
                    }
                  },

                  icon: const Icon(Icons.add, color: Colors.white),

                  label: const Text(
                    "Add Invoice",

                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          //-----------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Card(
                elevation: 2,

                child: Column(
                  children: [
                    Container(
                      height: 55,

                      color: Colors.grey.shade200,

                      child: const Row(
                        children: [
                          TableHeader("Invoice No", 1),

                          TableHeader("Customer", 2),

                          TableHeader("Date", 1),

                          TableHeader("Amount", 1),

                          TableHeader("Status", 1),

                          TableHeader("Action", 1),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ValueListenableBuilder<List<InvoiceRecord>>(
                        valueListenable: invoicesNotifier,
                        builder: (context, invoices, _) {
                          return ListView.builder(
                            itemCount: invoices.length,

                            itemBuilder: (context, index) {
                              final invoice = invoices[index];

                              return Container(
                                height: 60,

                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xffE0E0E0),
                                    ),
                                  ),
                                ),

                                child: Row(
                                  children: [
                                    tableCell(invoice.invoiceNo, 1),

                                    tableCell(invoice.customer, 2),

                                    tableCell(invoice.date, 1),

                                    tableCell("₹ ${invoice.amount}", 1),

                                    Expanded(
                                      child: Center(
                                        child: Chip(
                                          backgroundColor:
                                              invoice.status == "Paid"
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,

                                          label: Text(invoice.status),
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        children: [
                                          IconButton(
                                            onPressed: () {},

                                            icon: const Icon(
                                              Icons.edit,

                                              color: Colors.blue,
                                            ),
                                          ),

                                          IconButton(
                                            onPressed: () {},

                                            icon: const Icon(
                                              Icons.delete,

                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TableHeader extends StatelessWidget {
  final String title;

  final int flex;

  const TableHeader(this.title, this.flex, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),

        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

Widget tableCell(String text, int flex) {
  return Expanded(
    flex: flex,

    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),

      child: Text(text),
    ),
  );
}
