class Supplier {
  String name;
  String phone;
  String gst;
  double balance;

  Supplier({
    required this.name,
    required this.phone,
    required this.gst,
    required this.balance,
  });
}

List<Supplier> suppliers = [

  Supplier(
    name: "ABC Traders",
    phone: "9876543210",
    gst: "33AAAAA1111A1Z5",
    balance: 15000,
  ),

  Supplier(
    name: "XYZ Suppliers",
    phone: "9876549876",
    gst: "33BBBBB2222B1Z5",
    balance: 7000,
  ),

];

class Customer {
  String name;
  String phone;
  String gst;

  Customer({
    required this.name,
    required this.phone,
    required this.gst,
  });
}

List<Customer> customers = [

  Customer(
    name: "Tech Solutions",
    phone: "9876501234",
    gst: "29AAAAA0000A1Z5",
  ),

  Customer(
    name: "Smart Agencies",
    phone: "9123456789",
    gst: "29BBBBB1111B1Z5",
  ),

];

class Invoice {
  String invoiceNo;
  String customer;
  double total;

  Invoice({
    required this.invoiceNo,
    required this.customer,
    required this.total,
  });
}

List<Invoice> invoices = [

  Invoice(
    invoiceNo: "INV001",
    customer: "ABC Traders",
    total: 25000,
  ),

  Invoice(
    invoiceNo: "INV002",
    customer: "Tech Solutions",
    total: 9800,
  ),

];

class Estimate {
  String estimateNo;
  String customer;
  double amount;

  Estimate({
    required this.estimateNo,
    required this.customer,
    required this.amount,
  });
}

List<Estimate> estimates = [

  Estimate(
    estimateNo: "EST001",
    customer: "ABC Traders",
    amount: 18000,
  ),

  Estimate(
    estimateNo: "EST002",
    customer: "Smart Agencies",
    amount: 12000,
  ),

];