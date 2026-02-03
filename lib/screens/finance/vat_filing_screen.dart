import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_v3/models/vat_filing_data.dart';
import 'package:tailor_v3/services/excel_service.dart';
import 'package:tailor_v3/screens/finance/ledger_screen.dart';

class VatFilingScreen extends StatefulWidget {
  final String? initialFilePath;

  const VatFilingScreen({
    Key? key,
    this.initialFilePath,
  }) : super(key: key);

  @override
  State<VatFilingScreen> createState() => _VatFilingScreenState();
}

class _VatFilingScreenState extends State<VatFilingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExcelService _excelService = ExcelService();
  
  VatFilingData? _vatData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVatFilingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVatFilingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? filePath = widget.initialFilePath;

      // If no file path provided, get the most recent one
      if (filePath == null) {
        filePath = await _excelService.getMostRecentVatFilingFile();
      }

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

    // Show loading dialog
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
      Navigator.of(context).pop(); // Close loading dialog

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
      Navigator.of(context).pop(); // Close loading dialog

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
        title: const Text('VAT Filing - Data Manipulation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ledger', icon: Icon(Icons.book)),
            Tab(text: 'VAT Summary', icon: Icon(Icons.assessment)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
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
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLedgerTab(),
                        _buildVatSummaryTab(),
                      ],
                    ),
    );
  }

  Widget _buildLedgerTab() {
    return LedgerScreen(
      purchaseEntries: _vatData!.purchaseLedger,
      salesEntries: _vatData!.salesLedger,
      onEditPurchase: (index, updated) {
        setState(() {
          _vatData!.purchaseLedger[index] = updated;
          _vatData!.recalculateSummary();
        });
      },
      onEditSales: (index, updated) {
        setState(() {
          _vatData!.salesLedger[index] = updated;
          _vatData!.recalculateSummary();
        });
      },
    );
  }

  Widget _buildVatSummaryTab() {
    final summary = _vatData!.vatSummary;
    final currencyFormat = NumberFormat('#,##0.000');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VAT Summary for ${summary.taxPeriod}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(
            title: 'Output VAT (From Sales)',
            amount: summary.totalOutputVat,
            color: Colors.blue,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            title: 'Input VAT (From Purchases)',
            amount: summary.totalInputVat,
            color: Colors.orange,
            icon: Icons.trending_down,
          ),
          const SizedBox(height: 24),
          Divider(
            thickness: 2,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(
            title: 'Net VAT Payable',
            amount: summary.netVatPayable,
            color: summary.netVatPayable > 0
                ? Colors.red
                : summary.netVatPayable < 0
                    ? Colors.green
                    : Colors.grey,
            icon: summary.netVatPayable > 0
                ? Icons.arrow_upward
                : summary.netVatPayable < 0
                    ? Icons.arrow_downward
                    : Icons.remove,
            subtitle: summary.status,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Purchase Ledger Entries',
                  _vatData!.purchaseLedger.length.toString(),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Sales Ledger Entries',
                  _vatData!.salesLedger.length.toString(),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Claimable Input VAT',
                  currencyFormat.format(
                    _vatData!.purchaseLedger
                        .where((e) => e.isClaimable)
                        .fold(0.0, (sum, e) => sum + e.vatAmount),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Non-Claimable Input VAT',
                  currencyFormat.format(
                    _vatData!.purchaseLedger
                        .where((e) => !e.isClaimable)
                        .fold(0.0, (sum, e) => sum + e.vatAmount),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _editVatSummary,
                    child: const Text('Edit Summary Values'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    final currencyFormat = NumberFormat('#,##0.000');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }



  void _editVatSummary() {
    showDialog(
      context: context,
      builder: (context) => _EditVatSummaryDialog(
        summary: _vatData!.vatSummary,
        onSave: (updatedSummary) {
          setState(() {
            _vatData!.vatSummary = updatedSummary;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }
}



/// Dialog to edit VAT Summary
class _EditVatSummaryDialog extends StatefulWidget {
  final VatSummary summary;
  final Function(VatSummary) onSave;

  const _EditVatSummaryDialog({
    required this.summary,
    required this.onSave,
  });

  @override
  State<_EditVatSummaryDialog> createState() => _EditVatSummaryDialogState();
}

class _EditVatSummaryDialogState extends State<_EditVatSummaryDialog> {
  late TextEditingController _outputVatController;
  late TextEditingController _inputVatController;

  @override
  void initState() {
    super.initState();
    _outputVatController =
        TextEditingController(text: widget.summary.totalOutputVat.toString());
    _inputVatController =
        TextEditingController(text: widget.summary.totalInputVat.toString());
  }

  @override
  void dispose() {
    _outputVatController.dispose();
    _inputVatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit VAT Summary'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax Period: ${widget.summary.taxPeriod}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _outputVatController,
              decoration: const InputDecoration(
                labelText: 'Total Output VAT',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputVatController,
              decoration: const InputDecoration(
                labelText: 'Total Input VAT',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final outputVat = double.tryParse(_outputVatController.text) ?? 0.0;
    final inputVat = double.tryParse(_inputVatController.text) ?? 0.0;

    final updatedSummary = VatSummary(
      taxPeriod: widget.summary.taxPeriod,
      totalOutputVat: outputVat,
      totalInputVat: inputVat,
      netVatPayable: outputVat - inputVat,
    );

    widget.onSave(updatedSummary);
  }
}
