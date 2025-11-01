import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/excel_service.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({Key? key}) : super(key: key);

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Customer Details
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  
  // Sale Details
  DateTime _saleDate = DateTime.now();
  
  // Item Details
  String? _selectedItemId;
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  
  // Available items
  List<Map<String, dynamic>> _inventoryItems = [];
  Map<String, dynamic>? _selectedItem;
  
  // Calculations
  double _basePrice = 0.0;
  double _vatAmount = 0.0;
  double _totalPrice = 0.0;
  double _profit = 0.0;
  
  bool _isLoading = false;
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _quantityController.addListener(_calculateTotals);
    _unitPriceController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoadingItems = true;
    });

    try {
      final items = await ExcelService.instance.loadInventoryItemsFromExcel();
      setState(() {
        _inventoryItems = items.where((item) => 
          (item['currentStock'] as double? ?? 0.0) > 0
        ).toList();
        _isLoadingItems = false;
      });
    } catch (e) {
      print('Error loading inventory items: $e');
      setState(() {
        _isLoadingItems = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemSelected(String? itemId) {
    setState(() {
      _selectedItemId = itemId;
      if (itemId != null) {
        _selectedItem = _inventoryItems.firstWhere(
          (item) => item['id'] == itemId,
          orElse: () => {},
        );
        
        // Auto-fill unit price with selling price
        if (_selectedItem!.isNotEmpty) {
          final sellingPrice = _selectedItem!['sellingPrice'] as double? ?? 0.0;
          _unitPriceController.text = sellingPrice.toStringAsFixed(2);
        }
      } else {
        _selectedItem = null;
        _unitPriceController.clear();
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    
    if (quantity > 0 && unitPrice > 0) {
      // VAT-inclusive pricing: Unit Price includes 10% VAT
      // Base Price = Unit Price ÷ 1.10
      final basePrice = unitPrice / 1.10;
      final vatAmount = (basePrice * 0.10) * quantity;
      final totalPrice = unitPrice * quantity;
      
      // Calculate profit
      double profit = 0.0;
      if (_selectedItem != null && _selectedItem!.isNotEmpty) {
        final batchCostPrice = _selectedItem!['unitCost'] as double? ?? 0.0;
        profit = (basePrice - batchCostPrice) * quantity;
      }
      
      setState(() {
        _basePrice = basePrice * quantity;
        _vatAmount = vatAmount;
        _totalPrice = totalPrice;
        _profit = profit;
      });
    } else {
      setState(() {
        _basePrice = 0.0;
        _vatAmount = 0.0;
        _totalPrice = 0.0;
        _profit = 0.0;
      });
    }
  }

  void _showCreateOrderDialog() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final currentStock = _selectedItem!['currentStock'] as double? ?? 0.0;
    
    if (quantity > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock. Available: ${currentStock.toStringAsFixed(1)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isPaid = true; // Default to paid
    String? paymentMethod;
    
    print('🎯 Opening payment dialog with toggle...');
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Create Order',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Payment Status Toggle Section
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
                          // Status Display
                          Row(
                            children: [
                              Icon(
                                isPaid ? Icons.check_circle : Icons.schedule,
                                color: isPaid ? Colors.green : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isPaid ? 'PAID ORDER' : 'CREDIT ORDER',
                                style: TextStyle(
                                  color: isPaid ? Colors.green[700] : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Toggle Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Credit',
                                style: TextStyle(
                                  fontWeight: !isPaid ? FontWeight.bold : FontWeight.normal,
                                  color: !isPaid ? Colors.orange[700] : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              Switch(
                                value: isPaid,
                                onChanged: (value) {
                                  print('🔄 Toggle switched to: ${value ? "PAID" : "CREDIT"}');
                                  setDialogState(() {
                                    isPaid = value;
                                    if (!isPaid) {
                                      paymentMethod = null;
                                    }
                                  });
                                },
                                activeColor: Colors.green,
                                activeTrackColor: Colors.green[200],
                                inactiveThumbColor: Colors.orange,
                                inactiveTrackColor: Colors.orange[200],
                              ),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
                                  color: isPaid ? Colors.green[700] : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Method Section
                    if (isPaid) ...[
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[400]!, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: paymentMethod,
                            hint: const Text(
                              'Choose payment method...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: [
                              DropdownMenuItem(
                                value: 'Cash',
                                child: Row(
                                  children: [
                                    Icon(Icons.money, color: Colors.green[600], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Cash'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Card',
                                child: Row(
                                  children: [
                                    Icon(Icons.credit_card, color: Colors.blue[600], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Card'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Benefit',
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance, color: Colors.purple[600], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Benefit'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Bank Transfer',
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Colors.orange[600], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Bank Transfer'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Row(
                                  children: [
                                    Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Other'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              print('💳 Payment method selected: $value');
                              setDialogState(() {
                                paymentMethod = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Credit Order',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Payment will be collected later',
                                    style: TextStyle(
                                      color: Colors.orange[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Base Price:'),
                              Text('BHD ${_basePrice.toStringAsFixed(3)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('VAT (10%):'),
                              Text('BHD ${_vatAmount.toStringAsFixed(3)}'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'BHD ${_totalPrice.toStringAsFixed(3)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              print('❌ Dialog cancelled');
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isPaid && (paymentMethod == null || paymentMethod!.isEmpty)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a payment method'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              print('✅ Order confirmed: ${isPaid ? "PAID via $paymentMethod" : "CREDIT"}');
                              Navigator.of(dialogContext).pop();
                              _processSaleOrder(isPaid, paymentMethod);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPaid ? Colors.green[700] : Colors.orange[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              isPaid ? 'Complete Paid Order' : 'Create Credit Order',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Future<void> _processSaleOrder(bool isPaid, String? paymentMethod) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get next Sale ID
      final nextSaleId = await ExcelService.instance.getNextSaleId();
      
      // Ensure calculations are up to date before saving
      _calculateTotals();
      
      print('🔍 DEBUG NEW SALE: VAT Amount before saving: $_vatAmount');
      print('💳 DEBUG: Processing order - Paid: $isPaid, Method: ${paymentMethod ?? 'N/A'}');
      
      // Prepare sale data with payment information
      final saleData = {
        'saleId': nextSaleId.toString(),
        'date': DateFormat('yyyy-MM-dd').format(_saleDate),
        'customerName': _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerAddress': _customerAddressController.text.trim(),
        'vatAmount': _vatAmount, // Include calculated VAT amount
        'source': 'NEW_SALE_SCREEN', // Add source identifier
        'isPaid': isPaid,
        'paymentMethod': isPaid ? paymentMethod : '',
        'paymentStatus': isPaid ? 'Paid' : 'Credit',
        'items': [
          {
            'itemId': _selectedItem!['id'],
            'itemName': _selectedItem!['name'],
            'quantity': double.tryParse(_quantityController.text) ?? 0.0,
            'sellingPrice': double.tryParse(_unitPriceController.text) ?? 0.0,
            'wacCostPrice': _selectedItem!['unitCost'] as double? ?? 0.0,
          }
        ],
      };

      // Save the sale
      final success = await ExcelService.instance.saveSaleToExcel(saleData);

      if (success) {
        if (mounted) {
          final statusMessage = isPaid 
              ? 'Sale #$nextSaleId completed successfully!\nPayment: $paymentMethod'
              : 'Sale #$nextSaleId created as Credit order!\nPayment status: Credit (Unpaid)';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(statusMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to save sale');
      }
    } catch (e) {
      print('Error saving sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving sale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _showCreateOrderDialog,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Details Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Customer Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Customer name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Address (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sale Date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Sale Date',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _saleDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _saleDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd/MM/yyyy').format(_saleDate)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Item Details Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Item Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Item Selection
                      _isLoadingItems
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _selectedItemId,
                              decoration: const InputDecoration(
                                labelText: 'Select Item *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory_2),
                              ),
                              items: _inventoryItems.map<DropdownMenuItem<String>>((item) {
                                final stock = item['currentStock'] as double? ?? 0.0;
                                return DropdownMenuItem<String>(
                                  value: item['id']?.toString(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Unknown Item',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Stock: ${stock.toStringAsFixed(1)} • Cost: ${(item['unitCost'] as double? ?? 0.0).toStringAsFixed(2)} BHD',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: _onItemSelected,
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an item';
                                }
                                return null;
                              },
                            ),

                      if (_selectedItem != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Available Stock: ${(_selectedItem!['currentStock'] as double? ?? 0.0).toStringAsFixed(1)}'),
                              Text('Cost Price: ${(_selectedItem!['unitCost'] as double? ?? 0.0).toStringAsFixed(2)} BHD'),
                              Text('Suggested Price: ${(_selectedItem!['sellingPrice'] as double? ?? 0.0).toStringAsFixed(2)} BHD'),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.add_box),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final qty = double.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Please enter a valid quantity';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Unit Price (VAT Inclusive)
                      TextFormField(
                        controller: _unitPriceController,
                        decoration: InputDecoration(
                          labelText: 'Unit Price (VAT Inclusive) *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.monetization_on),
                          suffix: const Text('BD'),
                          helperText: 'Price includes 10% VAT',
                          helperStyle: TextStyle(color: Colors.grey[600]),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Unit price is required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calculation Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Sale Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Base Price (excl. VAT)', '${_basePrice.toStringAsFixed(2)} BHD'),
                      _buildSummaryRow('VAT Amount (10%)', '${_vatAmount.toStringAsFixed(2)} BHD'),
                      const Divider(),
                      _buildSummaryRow(
                        'Total Price',
                        '${_totalPrice.toStringAsFixed(2)} BHD',
                        isTotal: true,
                      ),
                      _buildSummaryRow(
                        'Estimated Profit',
                        '${_profit.toStringAsFixed(2)} BHD',
                        valueColor: _profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: valueColor ?? (isTotal ? Colors.green[700] : null),
            ),
          ),
        ],
      ),
    );
  }
}
