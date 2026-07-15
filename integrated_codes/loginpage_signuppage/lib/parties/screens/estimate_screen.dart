import 'package:flutter/material.dart';
import '../utils/app_data.dart';
import 'create_estimate_screen.dart';

class EstimateScreen extends StatelessWidget {
  const EstimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF2F5),
      body: Column(
        children: [
          Container(
            height: 65,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  "Estimate / Quotation",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search Estimate",
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
                    final estimate = await Navigator.push<EstimateRecord>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateEstimateScreen(),
                      ),
                    );
                    if (estimate != null) {
                      addEstimate(estimate);
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Estimate",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
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
                          TableHeader("Estimate No", 1),
                          TableHeader("Customer", 2),
                          TableHeader("Date", 1),
                          TableHeader("Amount", 1),
                          TableHeader("Status", 1),
                          TableHeader("Action", 1),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<List<EstimateRecord>>(
                        valueListenable: estimatesNotifier,
                        builder: (context, estimates, _) {
                          return ListView.builder(
                            itemCount: estimates.length,
                            itemBuilder: (context, index) {
                              final estimate = estimates[index];

                              return Container(
                                height: 60,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xffE5E5E5),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    tableCell(estimate.number, 1),
                                    tableCell(estimate.customer, 2),
                                    tableCell(estimate.date, 1),
                                    tableCell("₹ ${estimate.amount}", 1),
                                    Expanded(
                                      child: Center(
                                        child: Chip(
                                          backgroundColor:
                                              estimate.status == "Accepted"
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                          label: Text(estimate.status),
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

Widget tableCell(String value, int flex) {
  return Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(value),
    ),
  );
}
