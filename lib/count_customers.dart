import 'package:flutter/material.dart';
import 'services/excel_service.dart';

class CustomerCounter extends StatefulWidget {
  const CustomerCounter({super.key});

  @override
  State<CustomerCounter> createState() => _CustomerCounterState();
}

class _CustomerCounterState extends State<CustomerCounter> {
  int totalCustomers = 0;
  int validCustomers = 0;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _countCustomers();
  }

  Future<void> _countCustomers() async {
    try {
      final excelService = ExcelService();
      final customers = await excelService.loadCustomersFromExcel();
      
      setState(() {
        totalCustomers = customers.length;
        // Count customers with valid names and contacts (non-empty name and phone)
        validCustomers = customers.where((customer) {
          final name = customer['name']?.toString().trim() ?? '';
          final phone = customer['phone']?.toString().trim() ?? '';
          return name.isNotEmpty && phone.isNotEmpty;
        }).length;
        isLoading = false;
      });
      
      // Print to console for debugging
      print('Total customers in Excel file: $totalCustomers');
      print('Customers with valid name and contact: $validCustomers');
      
      // Print details of each customer
      for (int i = 0; i < customers.length; i++) {
        final customer = customers[i];
        final name = customer['name']?.toString().trim() ?? '';
        final phone = customer['phone']?.toString().trim() ?? '';
        print('Customer ${i + 1}: Name="$name", Phone="$phone"');
      }
      
    } catch (e) {
      setState(() {
        errorMessage = 'Error counting customers: $e';
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Counter'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage.isNotEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, color: Colors.blue, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Customer Count Results',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total entries in Excel file:'),
                                  Text(
                                    '$totalCustomers',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Valid customers\n(with name & contact):'),
                                  Text(
                                    '$validCustomers',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
