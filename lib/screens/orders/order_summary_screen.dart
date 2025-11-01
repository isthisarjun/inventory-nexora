import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/excel_service.dart';
import '../../models/order.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String customerId;
  final String items;
  final String materials;
  final String? description;
  final String? labourCost;
  final String? dueDate;
  final bool? includeVat; // New parameter for VAT inclusion

  const OrderSummaryScreen({
    Key? key,
    required this.customerId,
    required this.items,
    required this.materials,
    this.description,
    this.labourCost,
    this.dueDate,
    this.includeVat = true, // Default to include VAT
  }) : super(key: key);

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _excelService = ExcelService.instance;
  
  bool _isLoading = false;
  DateTime? _selectedDueDate;
  Map<String, dynamic>? _customerData;
  List<Map<String, dynamic>> _selectedOutfitItems = [];
  List<Map<String, dynamic>> _selectedMaterials = [];
  double _materialsCost = 0.0;
  double _labourCost = 0.0;
  double _totalCost = 0.0;
  
  // VAT-related state variables
  bool _includeVat = true;
  double _vatRate = 0.10; // 10% VAT rate
  double _vatAmount = 0.0;
  double _subtotal = 0.0;

  @override
  void initState() {
    super.initState();
    _includeVat = widget.includeVat ?? true; // Initialize from parameter
    _loadOrderData();
    _initializeFromParameters();
  }

  void _initializeFromParameters() {
    // Parse due date if provided
    if (widget.dueDate != null && widget.dueDate!.isNotEmpty) {
      try {
        _selectedDueDate = DateTime.parse(widget.dueDate!);
      } catch (e) {
        debugPrint('Error parsing due date: $e');
      }
    }

    // Parse labour cost if provided
    if (widget.labourCost != null && widget.labourCost!.isNotEmpty) {
      try {
        _labourCost = double.parse(widget.labourCost!);
      } catch (e) {
        debugPrint('Error parsing labour cost: $e');
      }
    }

    // Set VAT inclusion based on the parameter
    _includeVat = widget.includeVat ?? true;
  }

  Future<void> _loadOrderData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load customer data
      final customers = await _excelService.loadCustomersFromExcel();
      _customerData = customers.firstWhere(
        (c) => c['id'] == widget.customerId,
        orElse: () => {'id': widget.customerId, 'name': 'Unknown Customer'},
      );

      // Parse selected items
      _selectedOutfitItems = _parseSelectedItems();
      
      // Parse selected materials and calculate cost
      _selectedMaterials = await _parseSelectedMaterials();
      _calculateTotalCost();
      
    } catch (e) {
      debugPrint('Error loading order data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _parseSelectedItems() {
    if (widget.items.isEmpty) return [];
    
    final itemPairs = widget.items.split(',');
    final clothingTypes = [
      {'id': 'shirt', 'name': 'Shirt', 'icon': Icons.style},
      {'id': 'pants', 'name': 'Pants/Trousers', 'icon': Icons.directions_walk},
      {'id': 'suit', 'name': 'Suit', 'icon': Icons.business},
      {'id': 'jacket', 'name': 'Jacket/Blazer', 'icon': Icons.sports_handball},
      {'id': 'waistcoat', 'name': 'Waistcoat/Vest', 'icon': Icons.view_carousel},
      {'id': 'dress', 'name': 'Dress', 'icon': Icons.airline_seat_recline_normal},
      {'id': 'skirt', 'name': 'Skirt', 'icon': Icons.straighten},
      {'id': 'blouse', 'name': 'Blouse', 'icon': Icons.shopping_bag},
      {'id': 'kurta', 'name': 'Kurta/Pajama', 'icon': Icons.gradient},
    ];
    
    List<Map<String, dynamic>> result = [];
    
    for (final pair in itemPairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final itemId = parts[0];
        final quantity = int.tryParse(parts[1]) ?? 1;
        
        final clothingType = clothingTypes.firstWhere(
          (item) => item['id'] == itemId,
          orElse: () => {'id': itemId, 'name': 'Unknown Item', 'icon': Icons.help},
        );
        
        result.add({
          ...clothingType,
          'quantity': quantity,
        });
      }
    }
    
    return result;
  }

  Future<List<Map<String, dynamic>>> _parseSelectedMaterials() async {
    if (widget.materials.isEmpty) return [];
    
    final materialPairs = widget.materials.split(',');
    final allMaterials = await _excelService.loadMaterialStockFromExcel();
    List<Map<String, dynamic>> result = [];
    
    for (final pair in materialPairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final materialId = parts[0];
        final quantity = double.tryParse(parts[1]) ?? 0.0;
        
        final material = allMaterials.firstWhere(
          (m) => m['id'] == materialId,
          orElse: () => {'id': materialId, 'name': 'Unknown Material', 'price': 0.0},
        );
        
        result.add({
          ...material,
          'quantity': quantity,
        });
      }
    }
    
    return result;
  }

  void _calculateTotalCost() {
    _materialsCost = 0.0;
    for (final material in _selectedMaterials) {
      _materialsCost += (material['sellingPrice'] as double) * (material['quantity'] as double);
    }
    
    // Calculate subtotal (materials + labour)
    _subtotal = _materialsCost + _labourCost;
    
    // Calculate VAT and total
    if (_includeVat) {
      // VAT-inclusive pricing: Subtotal includes 10% VAT
      // Base Price = Subtotal ÷ 1.10, VAT Amount = Base Price × 0.10
      final basePriceSubtotal = _subtotal / 1.10;
      _vatAmount = basePriceSubtotal * _vatRate; // 10% VAT on base price
      _totalCost = _subtotal; // Total remains same since VAT is already included
    } else {
      _vatAmount = 0.0;
      _totalCost = _subtotal;
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  // Show payment selection dialog
  Future<Map<String, dynamic>?> _showPaymentSelectionDialog() async {
    final TextEditingController advanceController = TextEditingController();
    String selectedPaymentStatus = 'pay_at_delivery';
    double enteredAdvance = 0.0;
    
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 600,
            height: 500,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 20),
                      Icon(Icons.payment, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Payment Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Order Amount: BHD ${_totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Status:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          
                          // Payment Options
                          RadioListTile<String>(
                            title: const Text('Pay at Delivery', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Customer will pay when collecting the order', style: TextStyle(fontSize: 12)),
                            value: 'pay_at_delivery',
                            groupValue: selectedPaymentStatus,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPaymentStatus = value!;
                                if (value == 'paid') {
                                  enteredAdvance = _totalCost;
                                  advanceController.text = _totalCost.toStringAsFixed(2);
                                } else {
                                  enteredAdvance = 0.0;
                                  advanceController.text = '0.0';
                                }
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Paid (Full Payment)', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Customer has paid the full amount', style: TextStyle(fontSize: 12)),
                            value: 'paid',
                            groupValue: selectedPaymentStatus,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPaymentStatus = value!;
                                if (value == 'paid') {
                                  enteredAdvance = _totalCost;
                                  advanceController.text = _totalCost.toStringAsFixed(2);
                                } else {
                                  enteredAdvance = 0.0;
                                  advanceController.text = '0.0';
                                }
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Partial Payment', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Customer has paid a part of the amount', style: TextStyle(fontSize: 12)),
                            value: 'partial',
                            groupValue: selectedPaymentStatus,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPaymentStatus = value!;
                                enteredAdvance = 0.0;
                                advanceController.text = '';
                              });
                            },
                          ),
                          
                          if (selectedPaymentStatus == 'partial' || selectedPaymentStatus == 'paid') ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 60,
                              child: TextFormField(
                                controller: advanceController,
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                enabled: selectedPaymentStatus == 'partial',
                                decoration: const InputDecoration(
                                  labelText: 'Advance Amount (BHD)',
                                  border: OutlineInputBorder(),
                                  prefixText: 'BHD ',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (value) {
                                  enteredAdvance = double.tryParse(value) ?? 0.0;
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (enteredAdvance > 0)
                              Text(
                                'Remaining: BHD ${(_totalCost - enteredAdvance).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: (_totalCost - enteredAdvance) > 0 ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Validate advance amount
                          if (selectedPaymentStatus == 'partial' && enteredAdvance <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid advance amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (enteredAdvance > _totalCost) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Advance amount cannot exceed total amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          Navigator.of(context).pop({
                            'paymentStatus': selectedPaymentStatus == 'partial' ? 'pay_at_delivery' : selectedPaymentStatus,
                            'advanceAmount': enteredAdvance,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a due date'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Show payment selection dialog before creating order
    final paymentData = await _showPaymentSelectionDialog();
    if (paymentData == null) return; // User cancelled

    setState(() => _isLoading = true);

    try {
      // Create order object
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: widget.customerId,
        customerName: _customerData?['name'] ?? 'Unknown Customer',
        items: _selectedOutfitItems.map((item) => '${item['name']} (${item['quantity']})').toList(),
        materials: _selectedMaterials.map((m) => '${m['name']} (${m['quantity']})').toList(),
        materialsCost: _materialsCost,
        labourCost: _labourCost,
        totalCost: _totalCost,
        advanceAmount: paymentData['advanceAmount'] ?? 0.0,
        orderDate: DateTime.now(),
        dueDate: _selectedDueDate!,
        status: 'pending',
        paymentStatus: paymentData['paymentStatus'] ?? 'pay_at_delivery',
        vatAmount: _vatAmount,
        includeVat: _includeVat,
      );

      // Save order to Excel
      await _excelService.saveOrderToExcel(order.toMap());
      
      // Save individual sale details to sales tracking Excel
      await _saveSaleDetails(order);
      
      // Calculate and save profit for this order
      await _calculateAndSaveOrderProfit(order);
      
      // Update material stock
      await _updateMaterialStock();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sale created successfully!'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );

      // Navigate to all sales screen
      context.go('/all-orders');
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating order: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Calculate and save profit for an order
  Future<void> _calculateAndSaveOrderProfit(dynamic order) async {
    try {
      // Calculate revenue from selling price
      double revenue = _materialsCost + _labourCost; // This uses selling prices
      
      // Calculate cost using purchase cost of materials
      double cost = _labourCost; // Labour cost stays the same
      for (final material in _selectedMaterials) {
        cost += (material['purchaseCost'] as double) * (material['quantity'] as double);
      }
      
      // Calculate profit
      double profit = revenue - cost;
      
      // Save profit to Excel
      await _excelService.saveOrderProfit(
        order.id,
        revenue,
        cost,
        profit,
        _customerData?['name'] ?? 'Unknown Customer'
      );
      
      print('Order profit saved: Revenue=$revenue, Cost=$cost, Profit=$profit');
    } catch (e) {
      print('Error calculating/saving order profit: $e');
    }
  }

  /// Save individual sale details to the sales tracking Excel file
  Future<void> _saveSaleDetails(dynamic order) async {
    try {
      // Convert selected materials to sale items format
      List<Map<String, dynamic>> saleItems = [];
      
      for (final material in _selectedMaterials) {
        saleItems.add({
          'itemId': material['id']?.toString() ?? '',
          'itemName': material['name']?.toString() ?? '',
          'quantity': material['quantity']?.toString() ?? '0',
          'sellingPrice': material['sellingPrice']?.toString() ?? '0',
        });
      }
      
      // Prepare sale data with customer information and VAT amount
      final saleData = {
        'saleId': order.id,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'customerName': order.customerName.isNotEmpty ? order.customerName : 'Walk-in Customer',
        'vatAmount': _vatAmount, // Include calculated VAT amount
        'items': saleItems,
      };
      
      print('🔍 DEBUG ORDER SUMMARY: Subtotal: $_subtotal, VAT Amount: $_vatAmount, Total Cost: $_totalCost');
      
      // Save to sales tracking Excel
      await _excelService.saveSaleToExcel(saleData);
      
      print('Sale details saved to tracking Excel: ${order.id}');
    } catch (e) {
      print('Error saving sale details: $e');
    }
  }

  Future<void> _updateMaterialStock() async {
    for (final material in _selectedMaterials) {
      final materialId = material['id'] as String;
      final quantity = material['quantity'] as double;
      
      try {
        await _excelService.updateMaterialStock(materialId, quantity);
      } catch (e) {
        debugPrint('Failed to update stock for $materialId: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/work-details?customerId=${widget.customerId}&items=${widget.items}&materials=${widget.materials}'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Theme.of(context).colorScheme.primary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Steps 1-4 Complete',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 2, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '5',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Order summary content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer info
                          _buildCustomerInfo(),
                          const SizedBox(height: 20),
                          
                          // Selected items
                          _buildSelectedItems(),
                          const SizedBox(height: 20),
                          
                          // Selected materials
                          _buildSelectedMaterials(),
                          const SizedBox(height: 20),
                          
                          // Order details (description and labour cost)
                          if (widget.description != null && widget.description!.isNotEmpty ||
                              widget.labourCost != null && widget.labourCost!.isNotEmpty)
                            _buildOrderDetails(),
                          if (widget.description != null && widget.description!.isNotEmpty ||
                              widget.labourCost != null && widget.labourCost!.isNotEmpty)
                            const SizedBox(height: 20),
                          
                          // Due date selection
                          _buildDueDateSelector(),
                          const SizedBox(height: 20),
                          
                          // Total cost
                          _buildTotalCost(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Create order button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _customerData?['name'] ?? 'Unknown Customer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (_customerData?['phone'] != null)
              Text(
                _customerData!['phone'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            if (_customerData?['email'] != null)
              Text(
                _customerData!['email'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedItems() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checkroom,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected Clothing Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedOutfitItems.isEmpty)
              const Text('No items selected')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedOutfitItems.map((item) {
                  return Chip(
                    avatar: Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text('${item['name']} (${item['quantity']})'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMaterials() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected Materials',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedMaterials.isEmpty)
              const Text('No materials selected')
            else
              Column(
                children: _selectedMaterials.map((material) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(material['name'] as String),
                    subtitle: Text('${material['category']} • ${material['quantity']} units'),
                    trailing: Text(
                      'BHD ${((material['price'] as double) * (material['quantity'] as double)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Due Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDueDate == null
                            ? 'Select due date'
                            : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDueDate == null
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.primary,
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

  Widget _buildTotalCost() {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Materials cost
            if (_materialsCost > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Materials Cost',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'BHD ${_materialsCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Labour cost
            if (_labourCost > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Labour Cost',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'BHD ${_labourCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Subtotal
            if (_materialsCost > 0 || _labourCost > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'BHD ${_subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // VAT section with toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  // VAT toggle row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VAT (10%)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'BHD ${_vatAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _includeVat 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _includeVat,
                            onChanged: (value) {
                              setState(() {
                                _includeVat = value;
                                _calculateTotalCost();
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // VAT removal note
                  if (!_includeVat) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'VAT removed - will be recorded as 0 in VAT reports',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Divider(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.3),
              thickness: 1,
            ),
            const SizedBox(height: 8),
            
            // Total cost
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cost',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'BHD ${_totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Work Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            if (widget.description != null && widget.description!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work Description:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            // Labour Cost
            if (widget.labourCost != null && widget.labourCost!.isNotEmpty) ...[
              if (widget.description != null && widget.description!.isNotEmpty)
                const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.work,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Labour Cost: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'BHD ${widget.labourCost}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
