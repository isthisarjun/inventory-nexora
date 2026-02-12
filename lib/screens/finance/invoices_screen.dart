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
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _invoiceType = 'sales';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allOrders = await _excelService.loadOrdersFromExcel();
      final allPurchases = await _excelService.getGroupedPurchaseHistory();
      
      // Sort by order date (newest first)
      allOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a['orderDate']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['orderDate']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      for (final purchase in allPurchases) {
        purchase['invoiceType'] = 'purchase';
      }

      setState(() {
        _orders = allOrders;
        _purchases = allPurchases;
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
    final currentList = _invoiceType == 'sales' ? _orders : _purchases;
    if (_searchQuery.isEmpty) {
      return currentList;
    }
    return currentList.where((invoice) {
      final name = _getInvoiceName(invoice).toLowerCase();
      final invoiceId = _getInvoiceId(invoice).toLowerCase();
      final items = invoice['items']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || 
             invoiceId.contains(query) || 
             items.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
            tooltip: 'Back to Home',
          ),
          title: const Text('Invoices'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _invoiceType = index == 0 ? 'sales' : 'purchases';
                _searchQuery = '';
              });
            },
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text('Sales (${_orders.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping),
                    const SizedBox(width: 8),
                    Text('Purchases (${_purchases.length})'),
                  ],
                ),
              ),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
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
                      onPressed: _loadInvoices,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _filteredOrders.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.grey[50],
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search invoices by customer/vendor, invoice ID, or item...',
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
                      color: _invoiceType == 'sales' 
                        ? const Color(0xFFF2FBF6)
                        : const Color(0xFFFCF3E6),
                      child: Row(
                        children: [
                          Icon(
                            _invoiceType == 'sales' ? Icons.receipt_long : Icons.receipt,
                            color: _invoiceType == 'sales' 
                              ? const Color(0xFF0F9D58)
                              : const Color(0xFFF57C00),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_filteredOrders.length} ${_invoiceType == 'sales' ? 'Sales' : 'Purchase'} Invoice${_filteredOrders.length != 1 ? 's' : ''} Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _invoiceType == 'sales' 
                                ? const Color(0xFF0F9D58)
                                : const Color(0xFFF57C00),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total: BHD ${_calculateTotalValue().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _invoiceType == 'sales' 
                                ? const Color(0xFF0F9D58)
                                : const Color(0xFFF57C00),
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
                          final invoice = _filteredOrders[index];
                          return _buildInvoiceCard(invoice);
                        },
                      ),
                    ),
                  ],
                ),
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

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final isSales = invoice['invoiceType'] != 'purchase';
    final partyName = isSales ? _getCustomerName(invoice) : (invoice['vendorName'] ?? 'N/A');
    final invoiceId = _getInvoiceId(invoice);
    final invoiceDate = _getInvoiceDate(invoice);
    final totalAmount = double.tryParse(invoice['totalAmount']?.toString() ?? 
                       invoice['totalCost']?.toString() ?? '0') ?? 0.0;
    final paymentMethod = invoice['paymentMethod'] ?? invoice['paymentStatus'] ?? 'N/A';
    final status = invoice['status'] ?? invoice['paymentStatus'] ?? 'N/A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(invoice),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Party Name and Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      partyName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    'BHD ${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSales ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Invoice Details Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isSales ? 'Order' : 'Purchase'} ID: $invoiceId',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $invoiceDate',
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
                    'Tap to view ${isSales ? 'sales' : 'purchase'} details',
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

  String _getInvoiceName(Map<String, dynamic> invoice) {
    if (invoice['invoiceType'] == 'purchase') {
      return invoice['vendorName']?.toString() ?? 'N/A';
    }
    return _getCustomerName(invoice);
  }

  String _getInvoiceId(Map<String, dynamic> invoice) {
    if (invoice['invoiceType'] == 'purchase') {
      return invoice['purchaseId']?.toString() ?? invoice['id']?.toString() ?? 'N/A';
    }
    return invoice['orderId']?.toString() ?? invoice['id']?.toString() ?? 'N/A';
  }

  String _getInvoiceDate(Map<String, dynamic> invoice) {
    return invoice['date']?.toString() ??
        invoice['orderDate']?.toString() ??
        invoice['dateOfOrder']?.toString() ??
        'N/A';
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
    final isSales = order['invoiceType'] != 'purchase';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F9D58).withValues(alpha: 0.16),
                  const Color(0xFF34A853).withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F9D58),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isSales ? 'Sales Details' : 'Purchase Details',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailSection(
                              isSales ? 'Customer Information' : 'Vendor Information',
                              [
                                _buildDetailRow('Name', _getInvoiceName(order)),
                                _buildDetailRow(
                                  'Contact',
                                  order['customerPhone'] ??
                                      order['contact'] ??
                                      order['phone'] ??
                                      order['vendorContact'] ??
                                      order['vendorPhone'] ??
                                      'N/A',
                                ),
                                _buildDetailRow(
                                  isSales ? 'Order ID' : 'Purchase ID',
                                  _getInvoiceId(order),
                                ),
                                _buildDetailRow('Date', _getInvoiceDate(order)),
                                _buildDetailRow('Status', order['status'] ?? order['paymentStatus'] ?? 'N/A'),
                                if (order['paymentMethod'] != null && order['paymentMethod'].toString().isNotEmpty)
                                  _buildDetailRow('Payment Method', order['paymentMethod']),
                                if (order['paymentStatus'] != null && order['paymentStatus'].toString().isNotEmpty)
                                  _buildDetailRow('Payment Status', order['paymentStatus']),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Items purchased
                            _buildDetailSection(
                              'Items Purchased',
                              [
                                if (order['items'] != null && order['items'].toString().isNotEmpty)
                                  _buildItemsList(order['items'])
                                else if (order['outfitType'] != null)
                                  _buildDetailRow('Item', order['outfitType'])
                                else
                                  const Text('No items specified'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Financial Information
                            _buildDetailSection(
                              'Financial Summary',
                              [
                                _buildDetailRow(
                                  isSales ? 'Total Sales Amount' : 'Total Purchase Amount',
                                  'BHD ${(double.tryParse(order['totalAmount']?.toString() ?? '0') ?? 
                                      double.tryParse(order['totalCost']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                                ),
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Action buttons
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
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
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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
            color: Color(0xFF0F9D58),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFF2FBF6),
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
    return _filteredOrders.fold(0.0, (sum, invoice) {
      final totalAmount = double.tryParse(invoice['totalAmount']?.toString() ?? '0') ??
          double.tryParse(invoice['totalCost']?.toString() ?? '0') ?? 0.0;
      return sum + totalAmount;
    });
  }
}
