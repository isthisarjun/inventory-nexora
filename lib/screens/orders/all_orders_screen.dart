import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_v3/routes/app_routes.dart';
import 'package:tailor_v3/services/excel_service.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  bool _isLoading = true;
  final ExcelService _excelService = ExcelService();
  
  List<Map<String, dynamic>> _allOrders = [];
  String _statusFilter = 'all';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh orders when navigating to this screen
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load grouped sales records from sales_records.xlsx
      final groupedSalesRecords = await _excelService.getGroupedSalesFromExcel();
      
      setState(() {
        _allOrders = groupedSalesRecords;
      });
      
      debugPrint('Loaded ${groupedSalesRecords.length} grouped sales orders from Excel');
    } catch (e) {
      debugPrint('Error loading grouped sales records: $e');
      setState(() {
        _allOrders = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get filtered and sorted orders
  List<Map<String, dynamic>> get _filteredOrders {
    var filtered = _allOrders.where((order) {
      // Apply status filter
      if (_statusFilter != 'all') {
        final status = order['status']?.toString().toLowerCase() ?? '';
        if (status != _statusFilter) {
          return false;
        }
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final customerName = order['customerName']?.toString().toLowerCase() ?? '';
        final orderId = order['orderId']?.toString().toLowerCase() ?? '';
        final items = order['items']?.toString().toLowerCase() ?? '';
        
        if (!customerName.contains(query) && 
            !orderId.contains(query) && 
            !items.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort orders by order date (newest first for all orders)
    filtered.sort((a, b) {
      DateTime dateA = a['orderDate'] is DateTime 
          ? a['orderDate'] as DateTime 
          : DateTime.tryParse(a['orderDate']?.toString() ?? '') ?? DateTime.now();
      DateTime dateB = b['orderDate'] is DateTime 
          ? b['orderDate'] as DateTime 
          : DateTime.tryParse(b['orderDate']?.toString() ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); // Newest first
    });
    
    return filtered;
  }

  // Helper functions
  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    
    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
    
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        return date;
      }
    }
    
    return date.toString();
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in-progress':
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'ready':
        return 'Ready';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[700]!;
      case 'in-progress':
      case 'in_progress':
        return Colors.blue[700]!;
      case 'completed':
        return Colors.green[700]!;
      case 'ready':
        return Colors.green[800]!;
      case 'delivered':
        return Colors.green[900]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'in-progress':
      case 'in_progress':
        return Icons.construction;
      case 'completed':
        return Icons.check_circle;
      case 'ready':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final totalAmount = (order['totalCost'] ?? 0.0) as double;
    final profit = (order['profit'] ?? 0.0) as double;
    final quantity = (order['quantity'] ?? 0.0) as double;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🟢 GREEN HEADER SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sale #${order['orderId'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order['customerName'] ?? 'Unknown Customer'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDate(order['orderDate'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                'BHD ${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 📦 ITEMS DETAILS SECTION
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Items Sold',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Items list
                        if (order['itemsList'] != null && order['itemsList'].isNotEmpty)
                          ...order['itemsList'].map<Widget>((item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['itemName'] ?? 'Unknown Item',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailRow('Quantity', '${item['quantity']?.toStringAsFixed(1) ?? '0'}'),
                                    ),
                                    Expanded(
                                      child: _buildDetailRow('Total Sale', 'BHD ${item['totalSale']?.toStringAsFixed(2) ?? '0.00'}'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _buildDetailRow('Profit', 'BHD ${item['profit']?.toStringAsFixed(2) ?? '0.00'}', isProfit: true),
                              ],
                            ),
                          )).toList()
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              order['items']?.toString().trim().isNotEmpty == true
                                  ? order['items']
                                  : 'Items not specified',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 💰 TOTALS FOOTER SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Quantity:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${quantity.toStringAsFixed(1)} units',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'BHD ${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Profit:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'BHD ${profit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showReturnDialog(order);
                            },
                            icon: const Icon(Icons.keyboard_return),
                            label: const Text('Return'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReturnDialog(Map<String, dynamic> order) {
    // List to track which items are selected for return and their quantities
    Map<int, Map<String, dynamic>> returnItems = {};
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🟠 ORANGE HEADER SECTION
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.keyboard_return,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Return Items',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Sale #${order['orderId'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 📦 ITEMS SELECTION SECTION
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select items to return:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Items list for return selection
                            Expanded(
                              child: order['itemsList'] != null && order['itemsList'].isNotEmpty
                                  ? ListView.builder(
                                      itemCount: order['itemsList'].length,
                                      itemBuilder: (context, index) {
                                        final item = order['itemsList'][index];
                                        final originalQuantity = (item['quantity'] ?? 0.0) as double;
                                        final itemName = item['itemName'] ?? 'Unknown Item';
                                        final totalSale = (item['totalSale'] ?? 0.0) as double;
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: returnItems.containsKey(index) 
                                                ? Colors.orange[50] 
                                                : Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: returnItems.containsKey(index) 
                                                  ? Colors.orange[300]! 
                                                  : Colors.grey[200]!,
                                              width: returnItems.containsKey(index) ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: returnItems.containsKey(index),
                                                    onChanged: (bool? value) {
                                                      setStateDialog(() {
                                                        if (value == true) {
                                                          returnItems[index] = {
                                                            'itemName': itemName,
                                                            'originalQuantity': originalQuantity,
                                                            'returnQuantity': originalQuantity,
                                                            'totalSale': totalSale,
                                                            'unitPrice': totalSale / originalQuantity,
                                                          };
                                                        } else {
                                                          returnItems.remove(index);
                                                        }
                                                      });
                                                    },
                                                    activeColor: Colors.orange[600],
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      itemName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              if (returnItems.containsKey(index)) ...[
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Original Qty: ${originalQuantity.toStringAsFixed(1)}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Return Quantity:',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.orange[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 80,
                                                      child: TextFormField(
                                                        initialValue: returnItems[index]!['returnQuantity'].toString(),
                                                        keyboardType: TextInputType.number,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                          isDense: true,
                                                        ),
                                                        onChanged: (value) {
                                                          final newQuantity = double.tryParse(value) ?? 0.0;
                                                          if (newQuantity >= 0 && newQuantity <= originalQuantity) {
                                                            setStateDialog(() {
                                                              returnItems[index]!['returnQuantity'] = newQuantity;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Return Amount:',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.orange[700],
                                                      ),
                                                    ),
                                                    Text(
                                                      'BHD ${(returnItems[index]!['returnQuantity'] * returnItems[index]!['unitPrice']).toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ] else ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Quantity: ${originalQuantity.toStringAsFixed(1)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      'BHD ${totalSale.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Text(
                                        'No items available for return',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 💰 RETURN SUMMARY & ACTIONS SECTION
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (returnItems.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Return Amount:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                Text(
                                  'BHD ${returnItems.values.fold(0.0, (sum, item) => sum + (item['returnQuantity'] * item['unitPrice'])).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                ),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: returnItems.isEmpty 
                                    ? null 
                                    : () => _processReturn(order, returnItems),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Process Return'),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  void _processReturn(Map<String, dynamic> order, Map<int, Map<String, dynamic>> returnItems) {
    // Close the return dialog
    Navigator.of(context).pop();
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text('Confirm Return'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to process this return for Sale #${order['orderId']}?'),
              const SizedBox(height: 12),
              const Text('Items to return:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...returnItems.values.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${item['itemName']}: ${item['returnQuantity'].toStringAsFixed(1)} units'),
              )).toList(),
              const SizedBox(height: 12),
              Text(
                'Total refund: BHD ${returnItems.values.fold(0.0, (sum, item) => sum + (item['returnQuantity'] * item['unitPrice'])).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeReturn(order, returnItems);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Return'), 
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeReturn(Map<String, dynamic> order, Map<int, Map<String, dynamic>> returnItems) async {
    bool success = true;
    List<String> processedItems = [];
    List<String> failedItems = [];

    try {
      // Process each returned item
      for (final returnItem in returnItems.values) {
        final itemName = returnItem['itemName'] as String;
        final returnQuantity = returnItem['returnQuantity'] as double;
        
        try {
          // Find the item in inventory by name and add stock back
          final inventoryUpdated = await _addReturnedItemToInventory(itemName, returnQuantity);
          
          if (inventoryUpdated) {
            processedItems.add('$itemName (${returnQuantity.toStringAsFixed(1)} units)');
          } else {
            failedItems.add('$itemName (${returnQuantity.toStringAsFixed(1)} units)');
            success = false;
          }
        } catch (e) {
          debugPrint('Error processing return for item $itemName: $e');
          failedItems.add('$itemName (${returnQuantity.toStringAsFixed(1)} units)');
          success = false;
        }
      }

      // Create a return record for tracking
      await _createReturnRecord(order, returnItems);

      // Show appropriate success/failure message
      if (mounted) {
        if (success && failedItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Return processed successfully for Sale #${order['orderId']}. Items added back to inventory.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (processedItems.isNotEmpty) {
          // Partial success
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Return partially processed for Sale #${order['orderId']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (processedItems.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('✓ Successfully returned: ${processedItems.join(', ')}', 
                       style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
                if (failedItems.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('✗ Failed to return: ${failedItems.join(', ')}', 
                       style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 6),
          ),
        );
        } else {
          // Complete failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to process return for Sale #${order['orderId']}. Please try again.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error executing return: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error processing return: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    // Refresh the orders list to reflect any changes
    _loadOrders();
  }

  /// Find inventory item by name and add returned quantity back to stock
  Future<bool> _addReturnedItemToInventory(String itemName, double returnQuantity) async {
    try {
      // Load all inventory items to find the one with matching name
      final inventoryItems = await _excelService.loadInventoryItemsFromExcel();
      
      // Find item by name (case-insensitive)
      final matchingItem = inventoryItems.where((item) {
        final inventoryItemName = (item['name'] as String? ?? '').toLowerCase().trim();
        final searchItemName = itemName.toLowerCase().trim();
        return inventoryItemName == searchItemName;
      }).firstOrNull;
      
      if (matchingItem == null) {
        debugPrint('Item not found in inventory: $itemName');
        return false;
      }
      
      final itemId = matchingItem['id'] as String;
      debugPrint('Found item in inventory: $itemName (ID: $itemId)');
      
      // Add the returned quantity back to stock
      final success = await _excelService.addInventoryItemStock(itemId, returnQuantity);
      
      if (success) {
        debugPrint('Successfully added $returnQuantity units of $itemName back to inventory');
      } else {
        debugPrint('Failed to add $returnQuantity units of $itemName back to inventory');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error adding returned item to inventory: $e');
      return false;
    }
  }

  /// Create a record of the return transaction
  Future<void> _createReturnRecord(Map<String, dynamic> order, Map<int, Map<String, dynamic>> returnItems) async {
    try {
      // TODO: Implement return record creation
      // This could be a new sheet in Excel or a separate returns file
      // For now, just log the return details
      
      final returnDetails = {
        'returnDate': DateTime.now().toIso8601String(),
        'originalSaleId': order['orderId'],
        'customerName': order['customerName'],
        'returnedItems': returnItems.values.map((item) => {
          'itemName': item['itemName'],
          'returnQuantity': item['returnQuantity'],
          'returnAmount': item['returnQuantity'] * item['unitPrice'],
        }).toList(),
        'totalReturnAmount': returnItems.values.fold(0.0, 
          (sum, item) => sum + (item['returnQuantity'] * item['unitPrice'])),
      };
      
      debugPrint('Return record created: $returnDetails');
      
      // In a future implementation, you could:
      // 1. Save this to a returns_log.xlsx file
      // 2. Update the original sale record with return information
      // 3. Generate a return receipt
      // 4. Update financial records
      
    } catch (e) {
      debugPrint('Error creating return record: $e');
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isProfit = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
            color: isProfit
                ? (double.tryParse(value.replaceAll(' BHD', '')) ?? 0) >= 0
                    ? Colors.green[700]
                    : Colors.red[700]
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sales Records'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.newOrder),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter controls
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search sales by customer, ID, or items...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status filter
                      Row(
                        children: [
                          const Text('Filter: '),
                          DropdownButton<String>(
                            value: _statusFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Sales')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              DropdownMenuItem(value: 'ready', child: Text('Ready')),
                              DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value ?? 'all';
                              });
                            },
                          ),
                          const Spacer(),
                          Text(
                            '${_filteredOrders.length} sales',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Orders list
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? const Center(
                          child: Text(
                            'No sales found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () => _showOrderDetails(order),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Order header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                _getStatusIcon(order['status'] ?? ''),
                                                size: 16,
                                                color: _getStatusColor(order['status'] ?? ''),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(order['status'] as String),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  _formatStatus(order['status'] as String),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Sale #${order['orderId']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Customer and item info
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Customer name prominently displayed
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: Colors.blue[700],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        order['customerName']?.toString().trim().isNotEmpty == true 
                                                            ? order['customerName'] 
                                                            : 'Walk-in Customer',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: Colors.black87,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                // Items sold prominently displayed
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.shopping_bag,
                                                      size: 16,
                                                      color: Colors.green[700],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        order['itemCount'] != null && order['itemCount'] > 1
                                                            ? '${order['itemCount']} items total'
                                                            : (order['items']?.toString().trim().isNotEmpty == true 
                                                                ? 'Items: ${order['items']}' 
                                                                : 'Items: Not specified'),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.green[800],
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                // Quantity displayed
                                                if (order['quantity'] != null && order['quantity'] > 0)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.numbers,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Qty: ${order['quantity']?.toStringAsFixed(0) ?? '0'} units',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Date: ${_formatDate(order['orderDate'])}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (order['totalCost'] != null && order['totalCost'] != 0)
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Total Sale',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      'BHD ${order['totalCost'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (order['profit'] != null && order['profit'] != 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'Profit',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey[600],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        'BHD ${order['profit'].toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      // Tap hint
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Tap for details',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
