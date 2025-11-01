import 'package:flutter/material.dart';
import 'count_customers.dart';

void main() {
  runApp(const CustomerCounterApp());
}

class CustomerCounterApp extends StatelessWidget {
  const CustomerCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CustomerCounter(),
    );
  }
}
