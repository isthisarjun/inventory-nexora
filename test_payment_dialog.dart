// Simple test to verify the toggle-based payment dialog works
import 'package:flutter/material.dart';

void main() {
  runApp(const PaymentDialogTest());
}

class PaymentDialogTest extends StatelessWidget {
  const PaymentDialogTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Dialog Test',
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  void _showPaymentDialog() {
    bool isPaid = true;
    String? paymentMethod;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Payment Dialog Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Payment Status Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green[50] : Colors.orange[50],
                        border: Border.all(
                          color: isPaid ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isPaid ? 'PAID ORDER' : 'CREDIT ORDER',
                            style: TextStyle(
                              color: isPaid ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Credit'),
                              Switch(
                                value: isPaid,
                                onChanged: (value) {
                                  setDialogState(() {
                                    isPaid = value;
                                    if (!isPaid) {
                                      paymentMethod = null;
                                    }
                                  });
                                },
                                activeThumbColor: Colors.green,
                                inactiveThumbColor: Colors.orange,
                              ),
                              const Text('Paid'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Method (only when paid)
                    if (isPaid) ...[
                      const Text('Payment Method:'),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: paymentMethod,
                        hint: const Text('Select payment method'),
                        items: ['Cash', 'Card', 'Benefit'].map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            paymentMethod = value;
                          });
                        },
                      ),
                    ] else ...[
                      const Text(
                        'Credit order - payment later',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isPaid 
                                        ? 'Paid order created via $paymentMethod'
                                        : 'Credit order created',
                                  ),
                                ),
                              );
                            },
                            child: Text(isPaid ? 'Create Paid' : 'Create Credit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Dialog Test'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Payment Dialog Test\nPress button to show dialog',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPaymentDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.payment),
      ),
    );
  }
}