import 'package:flutter/foundation.dart';

const List<String> indianStates = [
  "Select State",
  "Andhra Pradesh",
  "Arunachal Pradesh",
  "Assam",
  "Bihar",
  "Chhattisgarh",
  "Goa",
  "Gujarat",
  "Haryana",
  "Himachal Pradesh",
  "Jharkhand",
  "Karnataka",
  "Kerala",
  "Madhya Pradesh",
  "Maharashtra",
  "Manipur",
  "Meghalaya",
  "Mizoram",
  "Nagaland",
  "Odisha",
  "Punjab",
  "Rajasthan",
  "Sikkim",
  "Tamil Nadu",
  "Telangana",
  "Tripura",
  "Uttar Pradesh",
  "Uttarakhand",
  "West Bengal",
  "Andaman and Nicobar Islands",
  "Chandigarh",
  "Dadra and Nagar Haveli and Daman and Diu",
  "Delhi",
  "Jammu and Kashmir",
  "Ladakh",
  "Lakshadweep",
  "Puducherry",
];

class CustomerRecord {
  final String name;
  final String phone;
  final String email;
  final String gst;
  final String state;
  final double balance;

  const CustomerRecord({
    required this.name,
    required this.phone,
    required this.email,
    required this.gst,
    required this.state,
    required this.balance,
  });
}

class SupplierRecord {
  final String name;
  final String phone;
  final String email;
  final String gst;
  final String state;
  final double balance;

  const SupplierRecord({
    required this.name,
    required this.phone,
    required this.email,
    required this.gst,
    required this.state,
    required this.balance,
  });
}

class InvoiceRecord {
  final String invoiceNo;
  final String customer;
  final String date;
  final double amount;
  final String status;

  const InvoiceRecord({
    required this.invoiceNo,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class EstimateRecord {
  final String number;
  final String customer;
  final String date;
  final double amount;
  final String status;

  const EstimateRecord({
    required this.number,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
  });
}

final ValueNotifier<List<CustomerRecord>> customersNotifier =
    ValueNotifier<List<CustomerRecord>>([
      const CustomerRecord(
        name: "ABC Traders",
        phone: "9876543210",
        email: "abc@gmail.com",
        gst: "33AAAAA1111A1Z5",
        state: "Tamil Nadu",
        balance: 5000,
      ),
      const CustomerRecord(
        name: "XYZ Enterprises",
        phone: "9123456789",
        email: "xyz@gmail.com",
        gst: "33BBBBB2222B1Z5",
        state: "Karnataka",
        balance: 2500,
      ),
      const CustomerRecord(
        name: "Tech Solutions",
        phone: "9876501234",
        email: "tech@example.com",
        gst: "29AAAAA0000A1Z5",
        state: "Karnataka",
        balance: 0,
      ),
    ]);

final ValueNotifier<List<SupplierRecord>> suppliersNotifier =
    ValueNotifier<List<SupplierRecord>>([
      const SupplierRecord(
        name: "ABC Traders",
        phone: "9876543210",
        email: "abc@gmail.com",
        gst: "33AAAAA1111A1Z5",
        state: "Tamil Nadu",
        balance: 15000,
      ),
      const SupplierRecord(
        name: "XYZ Suppliers",
        phone: "9876549876",
        email: "xyz@example.com",
        gst: "33BBBBB2222B1Z5",
        state: "Tamil Nadu",
        balance: 7000,
      ),
    ]);

final ValueNotifier<List<InvoiceRecord>> invoicesNotifier =
    ValueNotifier<List<InvoiceRecord>>([
      const InvoiceRecord(
        invoiceNo: "INV001",
        customer: "ABC Traders",
        date: "02/07/2026",
        amount: 12500,
        status: "Paid",
      ),
      const InvoiceRecord(
        invoiceNo: "INV002",
        customer: "XYZ Enterprises",
        date: "03/07/2026",
        amount: 8700,
        status: "Pending",
      ),
      const InvoiceRecord(
        invoiceNo: "INV003",
        customer: "Tech Solutions",
        date: "04/07/2026",
        amount: 21900,
        status: "Paid",
      ),
    ]);

final ValueNotifier<List<EstimateRecord>> estimatesNotifier =
    ValueNotifier<List<EstimateRecord>>([
      const EstimateRecord(
        number: "EST001",
        customer: "ABC Traders",
        date: "02/07/2026",
        amount: 15000,
        status: "Accepted",
      ),
      const EstimateRecord(
        number: "EST002",
        customer: "XYZ Enterprises",
        date: "04/07/2026",
        amount: 8300,
        status: "Pending",
      ),
      const EstimateRecord(
        number: "EST003",
        customer: "Tech Solutions",
        date: "05/07/2026",
        amount: 27500,
        status: "Accepted",
      ),
    ]);

void addCustomer(CustomerRecord customer) {
  customersNotifier.value = [...customersNotifier.value, customer];
}

void addSupplier(SupplierRecord supplier) {
  suppliersNotifier.value = [...suppliersNotifier.value, supplier];
}

void addInvoice(InvoiceRecord invoice) {
  invoicesNotifier.value = [...invoicesNotifier.value, invoice];
}

void updateInvoice(int index, InvoiceRecord invoice) {
  final invoices = [...invoicesNotifier.value];
  if (index < 0 || index >= invoices.length) return;
  invoices[index] = invoice;
  invoicesNotifier.value = invoices;
}

void deleteInvoice(int index) {
  final invoices = [...invoicesNotifier.value];
  if (index < 0 || index >= invoices.length) return;
  invoices.removeAt(index);
  invoicesNotifier.value = invoices;
}

void addEstimate(EstimateRecord estimate) {
  estimatesNotifier.value = [...estimatesNotifier.value, estimate];
}

void updateEstimate(int index, EstimateRecord estimate) {
  final estimates = [...estimatesNotifier.value];
  if (index < 0 || index >= estimates.length) return;
  estimates[index] = estimate;
  estimatesNotifier.value = estimates;
}

void deleteEstimate(int index) {
  final estimates = [...estimatesNotifier.value];
  if (index < 0 || index >= estimates.length) return;
  estimates.removeAt(index);
  estimatesNotifier.value = estimates;
}

double parseAmount(String value) {
  return double.tryParse(value.trim()) ?? 0;
}
