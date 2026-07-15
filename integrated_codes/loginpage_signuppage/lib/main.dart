import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/auth_container.dart';

void main() {
  runApp(const InvoiceBillApp());
}

class InvoiceBillApp extends StatelessWidget {
  const InvoiceBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InvoiceBill',
      debugShowCheckedModeBanner: false,
      theme: InvoiceBillTheme.lightTheme,
      home: const AuthContainer(),
    );
  }
}
