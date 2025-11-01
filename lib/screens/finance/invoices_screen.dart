import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../services/excel_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final ExcelService _excelService = ExcelService();
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allOrders = await _excelService.loadOrdersFromExcel();
      
      // Sort by order date (newest first)
      allOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a['orderDate']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['orderDate']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _orders = allOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty) {
      return _orders;
    }
    return _orders.where((order) {
      final customerName = _getCustomerName(order).toLowerCase();
      final orderId = order['orderId']?.toString().toLowerCase() ?? '';
      final items = order['items']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return customerName.contains(query) || 
             orderId.contains(query) || 
             items.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        title: const Text('Invoices'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _orders.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.grey[50],
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search invoices by customer, order ID, or item...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  
                  // Summary header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredOrders.length} Invoice${_filteredOrders.length != 1 ? 's' : ''} Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total Value: BHD ${_calculateTotalValue().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Invoice list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return _buildInvoiceCard(order);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Invoices Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invoices will appear here once orders are completed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/pending-orders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('View Pending Orders'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> order) {
    final customerName = _getCustomerName(order);
    final orderId = order['orderId'] ?? order['id'] ?? 'N/A';
    final orderDate = order['date'] ?? order['orderDate'] ?? 'N/A';
    final totalAmount = double.tryParse(order['totalAmount']?.toString() ?? '0') ?? 
                       double.tryParse(order['totalCost']?.toString() ?? '0') ?? 0.0;
    final paymentMethod = order['paymentMethod'] ?? 'N/A';
    final status = order['status'] ?? 'N/A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Customer Name and Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    'BHD ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order Details Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: $orderId',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $orderDate',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (paymentMethod != 'N/A') ...[
                        const SizedBox(height: 4),
                        Text(
                          paymentMethod,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tap for details hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view purchase details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCustomerName(Map<String, dynamic> order) {
    // Enhanced customer name extraction with multiple fallbacks
    if (order['customerName'] != null && order['customerName'].toString().trim().isNotEmpty) {
      return order['customerName'].toString().trim();
    } else if (order['customerId'] != null && order['customerId'].toString().trim().isNotEmpty) {
      return 'Customer ID: ${order['customerId']}';
    } else if (order['partyName'] != null && order['partyName'].toString().trim().isNotEmpty) {
      return order['partyName'].toString().trim();
    } else if (order['customer'] != null && order['customer'].toString().trim().isNotEmpty) {
      return order['customer'].toString().trim();
    }
    return 'N/A';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Purchase Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                
                // Customer Information
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Customer Information', [
                          _buildDetailRow('Name', _getCustomerName(order)),
                          _buildDetailRow('Contact', order['customerPhone'] ?? order['contact'] ?? order['phone'] ?? 'N/A'),
                          _buildDetailRow('Order ID', order['orderId'] ?? order['id'] ?? 'N/A'),
                          _buildDetailRow('Date', order['date'] ?? order['orderDate'] ?? 'N/A'),
                          _buildDetailRow('Status', order['status'] ?? 'N/A'),
                          if (order['paymentMethod'] != null && order['paymentMethod'].toString().isNotEmpty)
                            _buildDetailRow('Payment Method', order['paymentMethod']),
                        ]),
                        
                        const SizedBox(height: 24),
                        
                        // Items purchased
                        _buildDetailSection('Items Purchased', [
                          if (order['items'] != null && order['items'].toString().isNotEmpty)
                            _buildItemsList(order['items'])
                          else if (order['outfitType'] != null)
                            _buildDetailRow('Item', order['outfitType'])
                          else
                            const Text('No items specified'),
                        ]),
                        
                        const SizedBox(height: 24),
                        
                        // Financial Information
                        _buildDetailSection('Financial Summary', [
                          _buildDetailRow('Total Purchase Amount', 
                            'BHD ${(double.tryParse(order['totalAmount']?.toString() ?? '0') ?? 
                                double.tryParse(order['totalCost']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}'),
                          if (order['materialsCost'] != null && double.tryParse(order['materialsCost']?.toString() ?? '0') != 0)
                            _buildDetailRow('Materials Cost', 
                              'BHD ${double.tryParse(order['materialsCost']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
                          if (order['labourCost'] != null && double.tryParse(order['labourCost']?.toString() ?? '0') != 0)
                            _buildDetailRow('Labour Cost', 
                              'BHD ${double.tryParse(order['labourCost']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
                          if (order['advanceAmount'] != null && double.tryParse(order['advanceAmount']?.toString() ?? '0') != 0)
                            _buildDetailRow('Advance Paid', 
                              'BHD ${double.tryParse(order['advanceAmount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
                          if (order['vatAmount'] != null && double.tryParse(order['vatAmount']?.toString() ?? '0') != 0)
                            _buildDetailRow('VAT Amount', 
                              'BHD ${double.tryParse(order['vatAmount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}'),
                          if (order['paymentMethod'] != null && order['paymentMethod'].toString().isNotEmpty)
                            _buildDetailRow('Payment Method', order['paymentMethod']),
                          _buildDetailRow('Payment Status', order['paymentStatus'] ?? 'Unknown'),
                        ]),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Implement print functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Print functionality coming soon')),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(dynamic items) {
    if (items == null || items.toString().isEmpty) {
      return const Text('No items specified');
    }

    try {
      // Try to parse as JSON first (for structured item data)
      if (items is String && items.startsWith('[')) {
        final List<dynamic> itemList = jsonDecode(items);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: itemList.map((item) {
            if (item is Map<String, dynamic>) {
              return _buildDetailedItemRow(item);
            } else {
              return _buildSimpleItemRow(item.toString());
            }
          }).toList(),
        );
      } else if (items is List) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            if (item is Map<String, dynamic>) {
              return _buildDetailedItemRow(item);
            } else {
              return _buildSimpleItemRow(item.toString());
            }
          }).toList(),
        );
      } else {
        // Handle comma-separated string of items
        final String itemString = items.toString();
        final itemList = itemString.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: itemList.map((item) => _buildSimpleItemRow(item)).toList(),
        );
      }
    } catch (e) {
      // Fallback to simple string display
      return _buildSimpleItemRow(items.toString());
    }
  }

  Widget _buildDetailedItemRow(Map<String, dynamic> item) {
    final String itemName = item['name'] ?? item['itemName'] ?? item['item'] ?? 'Unknown Item';
    final double quantity = double.tryParse(item['quantity']?.toString() ?? '0') ?? 1.0;
    final double unitPrice = double.tryParse(item['unitPrice']?.toString() ?? item['price']?.toString() ?? '0') ?? 0.0;
    final double totalCost = quantity * unitPrice;
    final String quantityString = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$itemName x $quantityString',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unit Price: BHD ${unitPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Total: BHD ${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleItemRow(String item) {
    // Try to extract quantity from item string patterns 
    // Handle both "Item Name x 3" (new format) and "Item Name (3)" (legacy format)
    String itemName = item;
    String quantity = '1';
    
    // Check for new format: "Item Name x 3"
    final RegExp newFormatPattern = RegExp(r'(.+?)\s+x\s+(\d+\.?\d*)\s*$', caseSensitive: false);
    final newMatch = newFormatPattern.firstMatch(item);
    
    if (newMatch != null && newMatch.groupCount >= 2) {
      itemName = newMatch.group(1)?.trim() ?? item;
      final parsedQty = double.tryParse(newMatch.group(2) ?? '1') ?? 1.0;
      quantity = parsedQty % 1 == 0 ? parsedQty.toInt().toString() : parsedQty.toString();
    } else {
      // Check for legacy patterns like "Item Name (3)" or "Item Name - 3"
      final RegExp legacyPattern = RegExp(r'(.+?)\s*[\(\-\s]*[x\s]*(\d+\.?\d*)[x\)]?\s*$', caseSensitive: false);
      final legacyMatch = legacyPattern.firstMatch(item);
      
      if (legacyMatch != null && legacyMatch.groupCount >= 2) {
        itemName = legacyMatch.group(1)?.trim() ?? item;
        final parsedQty = double.tryParse(legacyMatch.group(2) ?? '1') ?? 1.0;
        quantity = parsedQty % 1 == 0 ? parsedQty.toInt().toString() : parsedQty.toString();
      }
    }
    
    // Always display in the standardized format: [item name] x [quantity]
    final displayText = '$itemName x $quantity';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(displayText)),
        ],
      ),
    );
  }

  double _calculateTotalValue() {
    return _filteredOrders.fold(0.0, (sum, order) {
      final totalCost = double.tryParse(order['totalCost']?.toString() ?? '0') ?? 0.0;
      return sum + totalCost;
    });
  }
}
