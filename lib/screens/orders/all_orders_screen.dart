import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:tailor_v3/routes/app_routes.dart';
import 'package:tailor_v3/services/excel_service.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  bool _isLoading = true;
  final ExcelService _excelService = ExcelService.instance;
  
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

      // Cross-reference returns_log.xlsx to mark returned orders
      final returnedOrderIds = await _getReturnedOrderIds();
      for (final order in groupedSalesRecords) {
        final orderId = order['orderId']?.toString() ?? '';
        if (returnedOrderIds.contains(orderId)) {
          order['status'] = 'returned';
        }
      }
      
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

  /// Returns the set of order IDs that have at least one entry in returns_log.xlsx.
  Future<Set<String>> _getReturnedOrderIds() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/returns_log.xlsx';
      final file = File(filePath);
      if (!await file.exists()) return {};
      final bytes = await file.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheet = excel['Returns'];
      final ids = <String>{};
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.length < 2) continue;
        final id = row[1]?.value?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
      return ids;
    } catch (e) {
      debugPrint('Error reading returned order IDs: $e');
      return {};
    }
  }

  // Get filtered and sorted orders
  List<Map<String, dynamic>> get _filteredOrders {
    var filtered = _allOrders.where((order) {
      // Apply status filter
      if (_statusFilter == 'credit') {
        final paymentStatus = order['paymentStatus']?.toString().toLowerCase() ?? '';
        if (paymentStatus != 'credit') return false;
      } else if (_statusFilter != 'all') {
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
      case 'returned':
        return 'Returned';
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
      case 'returned':
        return Colors.deepOrange[700]!;
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
      case 'returned':
        return Icons.keyboard_return;
      default:
        return Icons.help;
    }
  }

  /// Reads returns_log.xlsx and returns a map of {itemName: totalReturnedQty}
  /// for the given [orderId].
  Future<Map<String, double>> _getReturnedQuantitiesForOrder(String orderId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/returns_log.xlsx';
      final file = File(filePath);
      if (!await file.exists()) return {};

      final bytes = await file.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheet = excel['Returns'];

      final Map<String, double> returnedQtys = {};
      // Row 0 is the header; start from row 1
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.length < 5) continue;
        final rowOrderId = row[1]?.value?.toString() ?? '';
        if (rowOrderId == orderId) {
          final itemName = row[3]?.value?.toString() ?? '';
          final returnQty =
              double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0;
          returnedQtys[itemName] = (returnedQtys[itemName] ?? 0.0) + returnQty;
        }
      }
      return returnedQtys;
    } catch (e) {
      debugPrint('Error loading returned quantities: $e');
      return {};
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    // Load any previous returns for this order before opening the dialog
    final orderId = order['orderId']?.toString() ?? '';
    final returnedQuantities = await _getReturnedQuantitiesForOrder(orderId);
    final hasReturns = returnedQuantities.isNotEmpty;

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
                // 🟢/🟠 HEADER SECTION (orange when returned)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: hasReturns ? Colors.deepOrange[700] : Colors.green[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasReturns ? Icons.keyboard_return : Icons.receipt_long,
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
                          if (hasReturns)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.6)),
                              ),
                              child: const Text(
                                'RETURNED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
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
                                  _formatDate(order['orderDate']),
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
                          ...order['itemsList'].map<Widget>((item) {
                            final itemName = item['itemName'] ?? 'Unknown Item';
                            final originalQty = (item['quantity'] ?? 0.0) as double;
                            final returnedQty = returnedQuantities[itemName] ?? 0.0;
                            final netQty = (originalQty - returnedQty).clamp(0.0, double.infinity);
                            final isPartiallyReturned = returnedQty > 0;
                            return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isPartiallyReturned ? Colors.deepOrange[50] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPartiallyReturned ? Colors.deepOrange[200]! : Colors.grey[200]!,
                                width: isPartiallyReturned ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        itemName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isPartiallyReturned)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${returnedQty.toStringAsFixed(1)} returned',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange[800],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailRow(
                                        'Quantity',
                                        isPartiallyReturned
                                            ? '${netQty.toStringAsFixed(1)} (was ${originalQty.toStringAsFixed(1)})'
                                            : netQty.toStringAsFixed(1),
                                      ),
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
                          );
                          }).toList()
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
                          Builder(builder: (_) {
                            final totalReturned = returnedQuantities.values
                                .fold(0.0, (sum, q) => sum + q);
                            final netQty = (quantity - totalReturned).clamp(0.0, double.infinity);
                            return Text(
                              hasReturns
                                  ? '${netQty.toStringAsFixed(1)} units (${totalReturned.toStringAsFixed(1)} returned)'
                                  : '${quantity.toStringAsFixed(1)} units',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasReturns ? Colors.deepOrange[700] : Colors.black87,
                                fontWeight: hasReturns ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          }),
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
                      // The Return button below is always visible unless intentionally removed or hidden by a parent widget.
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
    // Controller for return reason description
    TextEditingController returnReasonController = TextEditingController();
    
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
                                                    SizedBox(
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

                    // � RETURN REASON SECTION
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Return Reason:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: returnReasonController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Please enter the reason for return (e.g., defective, wrong item, customer request)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // �💰 RETURN SUMMARY & ACTIONS SECTION
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
                                    : () => _processReturn(order, returnItems, returnReasonController.text.trim()),
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

  void _processReturn(Map<String, dynamic> order, Map<int, Map<String, dynamic>> returnItems, String returnReason) async {
    // Close the return dialog
    Navigator.of(context).pop();

    // Prepare data for Excel
    final List<List<dynamic>> rows = [];
    final String returnDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final String processedBy = 'LoggedInUser'; // Replace with actual user info if available

    returnItems.forEach((index, item) {
      rows.add([
        returnDate, // Return Date
        order['orderId'], // Original Sale ID
        order['customerName'], // Customer Name
        item['itemName'], // Item Name
        item['returnQuantity'], // Return Quantity
        (item['returnQuantity'] * item['unitPrice']).toStringAsFixed(2), // Return Amount
        returnReason, // Return Reason
        processedBy // Processed By
      ]);
    });

    try {
      // Load the returns_log.xlsx file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/returns_log.xlsx';
      final file = File(filePath);

      if (!await file.exists()) {
        // If file doesn't exist, create it with headers
        final excel = excel_lib.Excel.createExcel();
        final sheet = excel['Returns'];
        sheet.appendRow([
          'Return Date', 'Original Sale ID', 'Customer Name', 'Item Name', 'Return Quantity', 'Return Amount', 'Return Reason', 'Processed By'
        ]);
        await file.writeAsBytes(excel.encode()!);
      }

      // Append rows to the Excel file
      final bytes = await file.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheet = excel['Returns'];

      for (final row in rows) {
        sheet.appendRow(row);
      }

      // Save the updated Excel file
      await file.writeAsBytes(excel.encode()!);

      // Update the in-memory order status to 'returned' so the list card reflects it
      final orderId = order['orderId']?.toString();
      if (orderId != null) {
        setState(() {
          final idx = _allOrders.indexWhere(
              (o) => o['orderId']?.toString() == orderId);
          if (idx != -1) {
            _allOrders[idx] = Map<String, dynamic>.from(_allOrders[idx])
              ..['status'] = 'returned';
          }
        });
      }

      // Show success message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Return details have been successfully saved to returns_log.xlsx.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Show error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save return details: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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

  Future<void> _showCreditPaymentDialog(Map<String, dynamic> order) async {
    final saleId = order['orderId']?.toString() ?? '';
    final customerName = order['customerName']?.toString() ?? 'Unknown';
    final totalAmount = (order['totalCost'] as num?)?.toDouble() ?? 0.0;

    final alreadyPaid = await ExcelService.instance.getTotalPaidForSale(saleId);
    final remaining = totalAmount - alreadyPaid;

    if (!mounted) return;
    if (remaining <= 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This sale is already fully paid.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final amountController = TextEditingController(text: remaining.toStringAsFixed(3));
    final notesController = TextEditingController();
    String selectedMethod = 'Cash';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Credit Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sale #$saleId  •  $customerName',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryRow('Total Sale', totalAmount),
                        _summaryRow('Already Paid', alreadyPaid),
                        const Divider(height: 12),
                        _summaryRow('Remaining Balance', remaining, bold: true, color: Colors.red[700]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount Paying',
                      prefixText: 'BD ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter a valid amount';
                      if (val > remaining + 0.001) return 'Cannot exceed remaining (${remaining.toStringAsFixed(3)})';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'Benefit', child: Text('Benefit')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedMethod = v ?? 'Cash'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amountPaid = double.parse(amountController.text.trim());
                final notes = notesController.text.trim();
                Navigator.pop(ctx);
                await _processCreditPayment(order, amountPaid, remaining, selectedMethod, notes);
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color ?? Colors.black87,
      fontSize: 13,
    );
    final currency = NumberFormat.currency(symbol: 'BD ', decimalDigits: 3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(currency.format(amount), style: style),
        ],
      ),
    );
  }

  Future<void> _processCreditPayment(
    Map<String, dynamic> order,
    double amountPaid,
    double remaining,
    String paymentMethod,
    String notes,
  ) async {
    final saleId = order['orderId']?.toString() ?? '';
    final customerName = order['customerName']?.toString() ?? 'Unknown';
    final success = await ExcelService.instance.saveCreditPaymentToExcel(
      saleId: saleId,
      customerName: customerName,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save payment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final fullyPaid = amountPaid >= remaining - 0.001;
    if (fullyPaid) {
      await ExcelService.instance.updateSalePaymentStatus(saleId, 'Paid');
      if (mounted) {
        setState(() {
          final idx = _allOrders.indexWhere((o) => o['orderId'] == saleId);
          if (idx != -1) {
            _allOrders[idx] = Map<String, dynamic>.from(_allOrders[idx])
              ..['paymentStatus'] = 'paid'
              ..['status'] = 'completed';
          }
        });
      }
    }

    if (mounted) {
      final currency = NumberFormat.currency(symbol: 'BD ', decimalDigits: 3);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fullyPaid
                ? 'Payment of ${currency.format(amountPaid)} recorded. Sale fully paid!'
                : 'Payment of ${currency.format(amountPaid)} recorded. Remaining: ${currency.format(remaining - amountPaid)}',
          ),
          backgroundColor: fullyPaid ? Colors.green : Colors.orange[700],
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
                              DropdownMenuItem(value: 'credit', child: Text('Credit / Unpaid')),
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
                                              if (order['paymentStatus']?.toString().toLowerCase() == 'credit') ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[700],
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'UNPAID',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                      if (order['paymentStatus']?.toString().toLowerCase() == 'credit') ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showCreditPaymentDialog(order),
                                            icon: const Icon(Icons.payment, size: 16),
                                            label: const Text('Record Payment'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange[700],
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
