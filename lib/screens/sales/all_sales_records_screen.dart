import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/excel_service.dart';
// Removed import 'new_sale_screen.dart'; as NewSaleScreen class doesn't exist

class AllSalesRecordsScreen extends StatefulWidget {
  const AllSalesRecordsScreen({Key? key}) : super(key: key);

  @override
  State<AllSalesRecordsScreen> createState() => _AllSalesRecordsScreenState();
}

class _AllSalesRecordsScreenState extends State<AllSalesRecordsScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _sortBy = 'saleId'; // Default sort by Sale ID
  bool _sortAscending = false; // Default to descending (newest first)

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final salesData = await ExcelService.instance.loadSalesFromExcel();
      setState(() {
        _sales = salesData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sales: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sales: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAndSortedSales {
    var filtered = _sales.where((sale) {
      if (_searchTerm.isEmpty) return true;
      
      final searchLower = _searchTerm.toLowerCase();
      return (sale['saleId']?.toString().toLowerCase().contains(searchLower) ?? false) ||
             (sale['customerName']?.toString().toLowerCase().contains(searchLower) ?? false) ||
             (sale['itemName']?.toString().toLowerCase().contains(searchLower) ?? false);
    }).toList();

    // Sort the filtered results
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy];
      dynamic bValue = b[_sortBy];

      // Handle numeric sorting for Sale ID, Quantity, Prices
      if (_sortBy == 'saleId') {
        final aNum = int.tryParse(aValue?.toString() ?? '0') ?? 0;
        final bNum = int.tryParse(bValue?.toString() ?? '0') ?? 0;
        return _sortAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      } else if (_sortBy == 'quantitySold' || _sortBy == 'batchCostPrice' || 
                 _sortBy == 'sellingPrice' || _sortBy == 'vatAmount' || _sortBy == 'profit') {
        final aNum = double.tryParse(aValue?.toString() ?? '0') ?? 0.0;
        final bNum = double.tryParse(bValue?.toString() ?? '0') ?? 0.0;
        return _sortAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      } else if (_sortBy == 'date') {
        try {
          final aDate = DateTime.tryParse(aValue?.toString() ?? '') ?? DateTime.now();
          final bDate = DateTime.tryParse(bValue?.toString() ?? '') ?? DateTime.now();
          return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        } catch (e) {
          return 0;
        }
      } else {
        // String sorting
        final aStr = aValue?.toString().toLowerCase() ?? '';
        final bStr = bValue?.toString().toLowerCase() ?? '';
        return _sortAscending ? aStr.compareTo(bStr) : bStr.compareTo(aStr);
      }
    });

    return filtered;
  }

  void _sortByField(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = field;
        _sortAscending = true;
      }
    });
  }

  void _showSaleDetails(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Sale Details - ID: ${sale['saleId']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sale Information
                _buildDetailRow('Date', _formatDate(sale['date']?.toString() ?? '')),
                _buildDetailRow('Customer', sale['customerName']?.toString() ?? ''),
                _buildDetailRow('Item Name', sale['itemName']?.toString() ?? ''),
                _buildDetailRow('Quantity Sold', '${(double.tryParse(sale['quantitySold']?.toString() ?? '0') ?? 0.0).toStringAsFixed(1)} units'),
                _buildDetailRow('Batch Cost Price', '${(double.tryParse(sale['batchCostPrice']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD'),
                _buildDetailRow('Selling Price', '${(double.tryParse(sale['sellingPrice']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD'),
                _buildDetailRow('VAT Amount', '${(double.tryParse(sale['vatAmount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD'),
                _buildDetailRow('Profit', '${(double.tryParse(sale['profit']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD'),
                const Divider(height: 24),
                // Totals
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Revenue:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${((double.tryParse(sale['quantitySold']?.toString() ?? '0') ?? 0.0) * (double.tryParse(sale['sellingPrice']?.toString() ?? '0') ?? 0.0)).toStringAsFixed(2)} BHD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Profit:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(double.tryParse(sale['profit']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (double.tryParse(sale['profit']?.toString() ?? '0') ?? 0.0) >= 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
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

  Widget _buildSortableHeader(String title, String field, {double? width}) {
    final isCurrentSort = _sortBy == field;
    
    return InkWell(
      onTap: () => _sortByField(field),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentSort ? Colors.blue[800] : Colors.grey[800],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isCurrentSort)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Colors.blue[800],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sales Records'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSales,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Sales',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with search and add button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Sale ID, Customer, or Item...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
                // Removed the ElevatedButton.icon for New Sale
              ],
            ),
          ),
          
          // Sales summary
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  'Total Sales',
                  '${_filteredAndSortedSales.length}',
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Revenue',
                  '${_calculateTotalRevenue().toStringAsFixed(2)} BHD',
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total VAT',
                  '${_calculateTotalVAT().toStringAsFixed(2)} BHD',
                  Icons.account_balance,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Total Profit',
                  '${_calculateTotalProfit().toStringAsFixed(2)} BHD',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
          ),

          // Sales table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAndSortedSales.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No sales records found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first sale to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 12,
                            horizontalMargin: 16,
                            headingRowHeight: 56,
                            dataRowHeight: 48,
                            headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                            columns: [
                              DataColumn(
                                label: _buildSortableHeader('Sale ID', 'saleId', width: 80),
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Date', 'date', width: 100),
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Customer', 'customerName', width: 150),
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Item Name', 'itemName', width: 200),
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Qty Sold', 'quantitySold', width: 80),
                                numeric: true,
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Cost Price', 'batchCostPrice', width: 100),
                                numeric: true,
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Selling Price', 'sellingPrice', width: 110),
                                numeric: true,
                              ),
                              DataColumn(
                                label: _buildSortableHeader('VAT Amount', 'vatAmount', width: 100),
                                numeric: true,
                              ),
                              DataColumn(
                                label: _buildSortableHeader('Profit', 'profit', width: 100),
                                numeric: true,
                              ),
                            ],
                            rows: _filteredAndSortedSales.map((sale) {
                              final sellingPrice = double.tryParse(sale['sellingPrice']?.toString() ?? '0') ?? 0.0;
                              final profit = double.tryParse(sale['profit']?.toString() ?? '0') ?? 0.0;
                              final profitColor = profit >= 0 ? Colors.green[700] : Colors.red[700];

                              return DataRow(
                                cells: [
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showSaleDetails(sale),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          sale['saleId']?.toString() ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatDate(sale['date']?.toString() ?? ''),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      sale['customerName']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      sale['itemName']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (double.tryParse(sale['quantitySold']?.toString() ?? '0') ?? 0.0)
                                          .toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${(double.tryParse(sale['batchCostPrice']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD',
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${sellingPrice.toStringAsFixed(2)} BHD',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${(double.tryParse(sale['vatAmount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)} BHD',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange[700],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${profit.toStringAsFixed(2)} BHD',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: profitColor,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalRevenue() {
    return _filteredAndSortedSales.fold(0.0, (sum, sale) {
      final qty = double.tryParse(sale['quantitySold']?.toString() ?? '0') ?? 0.0;
      final price = double.tryParse(sale['sellingPrice']?.toString() ?? '0') ?? 0.0;
      return sum + (qty * price);
    });
  }

  double _calculateTotalVAT() {
    return _filteredAndSortedSales.fold(0.0, (sum, sale) {
      final vat = double.tryParse(sale['vatAmount']?.toString() ?? '0') ?? 0.0;
      return sum + vat;
    });
  }

  double _calculateTotalProfit() {
    return _filteredAndSortedSales.fold(0.0, (sum, sale) {
      final profit = double.tryParse(sale['profit']?.toString() ?? '0') ?? 0.0;
      return sum + profit;
    });
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
