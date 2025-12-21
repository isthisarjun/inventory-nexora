import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/excel_service.dart';
import '../../theme/colors.dart';
import '../../widgets/button.dart';

class VatReportScreen extends StatefulWidget {
  const VatReportScreen({super.key});

  @override
  State<VatReportScreen> createState() => _VatReportScreenState();
}

class _VatReportScreenState extends State<VatReportScreen> {
  final ExcelService _excelService = ExcelService();
  bool _isLoading = true;
  Map<String, dynamic> _vatSummary = {};
  List<Map<String, dynamic>> _standardRatedSales = [];
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadVatData();
  }

  Future<void> _loadVatData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load VAT summary
      final summary = await _excelService.calculateVatSummary(
        startDate: _startDate,
        endDate: _endDate,
      );
      
      // Load standard rated sales transactions
      final transactions = await _excelService.loadVatTransactions(
        startDate: _startDate,
        endDate: _endDate,
        type: 'Sale',
      );
      
      // Filter for standard rated sales (VAT rate > 0)
      final standardRated = transactions.where((t) => 
        (t['vatRate'] as double) > 0
      ).toList();

      setState(() {
        _vatSummary = summary;
        _standardRatedSales = standardRated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading VAT data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadVatData();
    }
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final filePath = await _excelService.exportVatReportToExcel(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _isLoading = false;
      });

      await Share.shareXFiles([XFile(filePath)]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('VAT report exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
        } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text('VAT Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            onRefresh: _loadVatData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Period',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          Button(
                            text: 'Change Date Range',
                            onPressed: _selectDateRange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // VAT Return Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VAT Return Summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Sales section
                          _buildVatSummarySection(
                            'Sales',
                            [
                              _buildVatSummaryRow('1. Standard rated sales', _vatSummary['standardRatedSales'] ?? 0.0),
                              _buildVatSummaryRow('2. Sales to GCC states', _vatSummary['salestoGCCStates'] ?? 0.0),
                              _buildVatSummaryRow('3. Exports', _vatSummary['exports'] ?? 0.0),
                              _buildVatSummaryRow('4. Zero rated sales', _vatSummary['zeroRatedSales'] ?? 0.0),
                              _buildVatSummaryRow('5. Exempt sales', _vatSummary['exemptSales'] ?? 0.0),
                              _buildVatSummaryRow('6. Total sales', _vatSummary['totalSales'] ?? 0.0, isTotal: true),
                              _buildVatSummaryRow('8. VAT on sales', _vatSummary['vatOnSales'] ?? 0.0, isVat: true),
                            ],
                          ),
                          
                          const Divider(height: 32),
                          
                          // Purchases section
                          _buildVatSummarySection(
                            'Purchases',
                            [
                              _buildVatSummaryRow('9. Standard rated purchases', _vatSummary['standardRatedPurchases'] ?? 0.0),
                              _buildVatSummaryRow('10. Imports subject to VAT', _vatSummary['importsSubjectToVat'] ?? 0.0),
                              _buildVatSummaryRow('12. Total purchases', _vatSummary['totalPurchases'] ?? 0.0, isTotal: true),
                              _buildVatSummaryRow('14. VAT on purchases', _vatSummary['vatOnPurchases'] ?? 0.0, isVat: true),
                            ],
                          ),
                          
                          const Divider(height: 32),
                          
                          // Net VAT
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '15. Net VAT due (or reclaimed)',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'BHD ${(_vatSummary['netVatDue'] ?? 0.0).toStringAsFixed(3)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: (_vatSummary['netVatDue'] ?? 0.0) >= 0 
                                      ? Colors.red 
                                      : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Standard Rated Sales Details
                  if (_standardRatedSales.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard Rated Sales (5% VAT)',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: _buildTableHeader('TRN')),
                                  Expanded(flex: 3, child: _buildTableHeader('Description')),
                                  Expanded(flex: 2, child: _buildTableHeader('Date')),
                                  Expanded(flex: 2, child: _buildTableHeader('Taxable Value')),
                                  Expanded(flex: 2, child: _buildTableHeader('VAT Amount')),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Table rows
                            ...(_standardRatedSales.take(10).map((transaction) => 
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        transaction['trn'] ?? '',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        transaction['description'] ?? '',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        DateFormat('dd/MM/yy').format(transaction['date']),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'BHD ${(transaction['taxableValue'] as double).toStringAsFixed(3)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'BHD ${(transaction['vatAmount'] as double).toStringAsFixed(3)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                            
                            if (_standardRatedSales.length > 10)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  'Showing 10 of ${_standardRatedSales.length} transactions. Export to Excel for full details.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Export button
                  Button(
                    text: 'Export Full Report to Excel',
                    onPressed: _exportToExcel,
                    icon: Icons.file_download,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildVatSummarySection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }

  Widget _buildVatSummaryRow(String label, double amount, {bool isTotal = false, bool isVat = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal || isVat ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            'BHD ${amount.toStringAsFixed(3)}',              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal || isVat ? FontWeight.bold : FontWeight.normal,
                color: isVat ? AppColors.primary : null,
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
