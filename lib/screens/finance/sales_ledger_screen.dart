import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/models/vat_filing_data.dart';
import 'package:tailor_v3/services/excel_service.dart';

class SalesLedgerScreen extends StatefulWidget {
  const SalesLedgerScreen({super.key});

  @override
  State<SalesLedgerScreen> createState() => _SalesLedgerScreenState();
}

class _SalesLedgerScreenState extends State<SalesLedgerScreen> {
  final ExcelService _excelService = ExcelService();
  VatFilingData? _vatData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVatFilingData();
  }

  Future<void> _loadVatFilingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? filePath = await _excelService.getMostRecentVatFilingFile();

      if (filePath == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No VAT filing data found. Please generate a VAT filing workbook first.';
        });
        return;
      }

      final vatData = await _excelService.loadVatFilingData(filePath);

      if (vatData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load VAT filing data from the file.';
        });
        return;
      }

      setState(() {
        _vatData = vatData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading VAT filing data: $e';
      });
    }
  }

  Future<void> _exportModifiedData() async {
    if (_vatData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting modified data...'),
          ],
        ),
      ),
    );

    try {
      final filePath = await _excelService.exportVatFilingDataToExcel(_vatData!);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully to:\n$filePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          if (_vatData != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _exportModifiedData,
              tooltip: 'Export Modified Data',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVatFilingData,
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
                        onPressed: _loadVatFilingData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _vatData == null
                  ? const Center(child: Text('No data available'))
                  : _buildSalesLedgerTable(),
    );
  }

  Widget _buildSalesLedgerTable() {
    final salesEntries = _vatData!.salesLedger;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Sales Ledger (Output VAT)',
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
                    '${salesEntries.length} entries',
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
                DataColumn(label: Text('Net Sales')),
                DataColumn(label: Text('VAT Rate %')),
                DataColumn(label: Text('VAT Amount')),
                DataColumn(label: Text('Total Collected')),
                DataColumn(label: Text('Actions')),
              ],
              rows: salesEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return DataRow(cells: [
                  DataCell(Text(e.date)),
                  DataCell(Text(e.receiptId)),
                  DataCell(Text(e.customerName)),
                  DataCell(Text(e.netSales.toStringAsFixed(3))),
                  DataCell(Text('${e.vatRate.toStringAsFixed(1)}%')),
                  DataCell(Text(e.vatAmount.toStringAsFixed(3))),
                  DataCell(Text(e.totalCollected.toStringAsFixed(3))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _EditSalesLedgerDialog(
                        entry: e,
                        onSave: (updatedEntry) {
                          setState(() {
                            _vatData!.salesLedger[idx] = updatedEntry;
                            _vatData!.recalculateSummary();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    tooltip: 'Edit',
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSalesLedgerDialog extends StatefulWidget {
  final SalesLedgerEntry entry;
  final Function(SalesLedgerEntry) onSave;

  const _EditSalesLedgerDialog({
    required this.entry,
    required this.onSave,
  });

  @override
  State<_EditSalesLedgerDialog> createState() => _EditSalesLedgerDialogState();
}

class _EditSalesLedgerDialogState extends State<_EditSalesLedgerDialog> {
  late TextEditingController _netSalesController;
  late TextEditingController _vatAmountController;

  @override
  void initState() {
    super.initState();
    _netSalesController = TextEditingController(text: widget.entry.netSales.toString());
    _vatAmountController = TextEditingController(text: widget.entry.vatAmount.toString());
  }

  @override
  void dispose() {
    _netSalesController.dispose();
    _vatAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Sales Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt: ${widget.entry.receiptId}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Customer: ${widget.entry.customerName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _netSalesController,
              decoration: const InputDecoration(labelText: 'Net Sales', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vatAmountController,
              decoration: const InputDecoration(labelText: 'VAT Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
      ],
    );
  }

  void _saveChanges() {
    final netSales = double.tryParse(_netSalesController.text) ?? 0.0;
    final vatAmount = double.tryParse(_vatAmountController.text) ?? 0.0;

    final updatedEntry = widget.entry.copyWith(
      netSales: netSales,
      vatAmount: vatAmount,
      totalCollected: netSales + vatAmount,
    );

    widget.onSave(updatedEntry);
  }
}
