import 'package:flutter/material.dart';
import '../dialogs/add_customer_dialog.dart';
import '../utils/app_data.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Row(
              children: const [
                CustomerList(),
                VerticalDivider(width: 1),
                Expanded(child: CustomerDetails()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

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
                  "Customers",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                ValueListenableBuilder<List<CustomerRecord>>(
                  valueListenable: customersNotifier,
                  builder: (context, customers, _) {
                    return CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        "${customers.length}",
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
                prefixIcon: Icon(Icons.search),
                hintText: "Search customer...",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    "CUSTOMER NAME",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Text("BALANCE", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<List<CustomerRecord>>(
              valueListenable: customersNotifier,
              builder: (context, customers, _) {
                if (customers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No customers found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = customers[index];

                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      trailing: Text(
                        "₹ ${customer.balance.toStringAsFixed(0)}",
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

class CustomerDetails extends StatelessWidget {
  const CustomerDetails({super.key});

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
                const Text("Customers", style: TextStyle(fontSize: 24)),

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
                            final customer = await showDialog<CustomerRecord>(
                              context: context,
                              builder: (_) => const AddCustomerDialog(),
                            );
                            if (customer != null) {
                              addCustomer(customer);
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Add Customer",
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
                  Icon(Icons.person_outline, size: 90, color: Colors.grey),

                  SizedBox(height: 20),

                  Text(
                    "Select a customer to view details",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
