import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/models/vat_filing_data.dart';
import 'package:tailor_v3/services/excel_service.dart';

class PurchaseLedgerScreen extends StatefulWidget {
  const PurchaseLedgerScreen({super.key});

  @override
  State<PurchaseLedgerScreen> createState() => _PurchaseLedgerScreenState();
}

class _PurchaseLedgerScreenState extends State<PurchaseLedgerScreen> {
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
        title: const Text('Purchase Ledger'),
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
                  : _buildPurchaseLedgerTable(),
    );
  }

  Widget _buildPurchaseLedgerTable() {
    final purchaseEntries = _vatData!.purchaseLedger;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Purchase Ledger (Input VAT)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${purchaseEntries.length} entries',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green[800]),
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
                DataColumn(label: Text('Invoice ID')),
                DataColumn(label: Text('Vendor')),
                DataColumn(label: Text('Net Amount')),
                DataColumn(label: Text('VAT Rate %')),
                DataColumn(label: Text('VAT Amount')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Claimable')),
                DataColumn(label: Text('Actions')),
              ],
              rows: purchaseEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return DataRow(cells: [
                  DataCell(Text(e.date)),
                  DataCell(Text(e.invoiceId)),
                  DataCell(Text(e.vendorName)),
                  DataCell(Text(e.netAmount.toStringAsFixed(3))),
                  DataCell(Text('${e.vatRate.toStringAsFixed(1)}%')),
                  DataCell(Text(e.vatAmount.toStringAsFixed(3))),
                  DataCell(Text(e.totalAmount.toStringAsFixed(3))),
                  DataCell(Chip(
                    label: Text(e.isClaimable ? 'Yes' : 'No'),
                    backgroundColor: e.isClaimable ? Colors.green[100] : Colors.red[100],
                    labelStyle: TextStyle(color: e.isClaimable ? Colors.green[800] : Colors.red[800]),
                  )),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _EditPurchaseLedgerDialog(
                        entry: e,
                        onSave: (updatedEntry) {
                          setState(() {
                            _vatData!.purchaseLedger[idx] = updatedEntry;
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

class _EditPurchaseLedgerDialog extends StatefulWidget {
  final PurchaseLedgerEntry entry;
  final Function(PurchaseLedgerEntry) onSave;

  const _EditPurchaseLedgerDialog({
    required this.entry,
    required this.onSave,
  });

  @override
  State<_EditPurchaseLedgerDialog> createState() => _EditPurchaseLedgerDialogState();
}

class _EditPurchaseLedgerDialogState extends State<_EditPurchaseLedgerDialog> {
  late TextEditingController _netAmountController;
  late TextEditingController _vatAmountController;
  late bool _isClaimable;

  @override
  void initState() {
    super.initState();
    _netAmountController = TextEditingController(text: widget.entry.netAmount.toString());
    _vatAmountController = TextEditingController(text: widget.entry.vatAmount.toString());
    _isClaimable = widget.entry.isClaimable;
  }

  @override
  void dispose() {
    _netAmountController.dispose();
    _vatAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Purchase Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${widget.entry.invoiceId}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Vendor: ${widget.entry.vendorName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _netAmountController,
              decoration: const InputDecoration(labelText: 'Net Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vatAmountController,
              decoration: const InputDecoration(labelText: 'VAT Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Is Claimable?'),
              value: _isClaimable,
              onChanged: (value) => setState(() => _isClaimable = value ?? true),
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
    final netAmount = double.tryParse(_netAmountController.text) ?? 0.0;
    final vatAmount = double.tryParse(_vatAmountController.text) ?? 0.0;

    final updatedEntry = widget.entry.copyWith(
      netAmount: netAmount,
      vatAmount: vatAmount,
      isClaimable: _isClaimable,
      totalAmount: netAmount + vatAmount,
    );

    widget.onSave(updatedEntry);
  }
}
