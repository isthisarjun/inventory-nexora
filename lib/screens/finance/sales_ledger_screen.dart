import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/services/excel_service.dart';

class SalesLedgerScreen extends StatefulWidget {
  const SalesLedgerScreen({super.key});

  @override
  State<SalesLedgerScreen> createState() => _SalesLedgerScreenState();
}

class _SalesLedgerScreenState extends State<SalesLedgerScreen> {
  final ExcelService _excelService = ExcelService();
  List<Map<String, dynamic>> _salesData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSalesLedger();
  }

  Future<void> _loadSalesLedger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load sales records directly from sales_records.xlsx
      final salesRecords = await _excelService.getGroupedSalesFromExcel();

      if (salesRecords.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No sales records found in sales_records.xlsx';
        });
        return;
      }

      // Convert to ledger format with all necessary fields
      List<Map<String, dynamic>> ledgerEntries = [];
      for (var sale in salesRecords) {
        // Map from Excel columns:
        // Column H: Total Amount (totalAmount)
        // Column I: VAT Amount (vatAmount)
        // Column J: Net Sales (netSales)
        final totalAmount = double.tryParse(sale['totalAmount']?.toString() ?? '0') ?? 0.0;
        final vatAmount = double.tryParse(sale['vatAmount']?.toString() ?? '0') ?? 0.0;
        final netSales = double.tryParse(sale['netSales']?.toString() ?? '0') ?? 0.0;
        
        ledgerEntries.add({
          'date': sale['date'] ?? sale['orderDate'] ?? 'N/A',
          'receiptId': sale['orderId'] ?? sale['id'] ?? 'N/A',
          'customerName': sale['customerName'] ?? 'Walk-in Customer',
          'netSales': netSales,
          'vatRate': 5.0,
          'vatAmount': vatAmount,
          'totalCollected': totalAmount,
        });
      }

      setState(() {
        _salesData = ledgerEntries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading sales ledger: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
          tooltip: 'Back to Accounts',
        ),
        title: const Text('Sales Ledger'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalesLedger,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadSalesLedger,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _salesData.isEmpty
                  ? const Center(child: Text('No sales data available'))
                  : _buildSalesLedgerTable(),
    );
  }

  Widget _buildSalesLedgerTable() {
    double totalNetSales = 0;
    double totalVat = 0;
    double totalCollected = 0;

    for (var entry in _salesData) {
      totalNetSales += entry['netSales'] as double;
      totalVat += entry['vatAmount'] as double;
      totalCollected += entry['totalCollected'] as double;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Sales Ledger',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_salesData.length} entries',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Receipt ID')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Net Sales (BHD)')),
                DataColumn(label: Text('VAT Rate %')),
                DataColumn(label: Text('VAT Amount (BHD)')),
                DataColumn(label: Text('Total (BHD)')),
              ],
              rows: _salesData.map((entry) {
                return DataRow(cells: [
                  DataCell(Text(entry['date']?.toString() ?? '')),
                  DataCell(Text(entry['receiptId']?.toString() ?? '')),
                  DataCell(Text(entry['customerName']?.toString() ?? '')),
                  DataCell(Text((entry['netSales'] as double).toStringAsFixed(3))),
                  DataCell(Text('${(entry['vatRate'] as double).toStringAsFixed(1)}%')),
                  DataCell(Text((entry['vatAmount'] as double).toStringAsFixed(3))),
                  DataCell(Text((entry['totalCollected'] as double).toStringAsFixed(3))),
                ]);
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total Net Sales: BHD ${totalNetSales.toStringAsFixed(3)}', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Total VAT: BHD ${totalVat.toStringAsFixed(3)}', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Total Collected: BHD ${totalCollected.toStringAsFixed(3)}', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
