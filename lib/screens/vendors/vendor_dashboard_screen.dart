import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/excel_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/simple_navigation.dart';

class VendorDashboardScreen extends StatefulWidget {
  final String vendorName;
  
  const VendorDashboardScreen({
    super.key,
    required this.vendorName,
  });

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  late FocusNode _focusNode;
  Map<String, dynamic>? _vendorData;
  List<Map<String, dynamic>> _vendorTransactions = [];
  List<Map<String, dynamic>> _recentPurchases = [];
  bool _isLoading = true;
  String? _error;

  // Payment-related controllers and variables
  final TextEditingController _paymentAmountController = TextEditingController();
  final TextEditingController _paymentReferenceController = TextEditingController();
  final TextEditingController _paymentNotesController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedPaymentDate = DateTime.now();
  bool _isProcessingPayment = false;
  
  // Payment methods list
  final List<String> _paymentMethods = ['Cash', 'Bank Transfer', 'Check', 'Credit Card', 'Online Payment'];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadVendorData();
    print('📊 VendorDashboardScreen initialized with ESC key support');
    
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      print('🎯 Focus requested for VendorDashboardScreen');
    });
  }

  Future<void> _loadVendorData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load vendor details
      final vendors = await ExcelService.instance.loadVendorsFromExcel();
      _vendorData = vendors.firstWhere(
        (v) => v['vendorName'] == widget.vendorName,
        orElse: () => {},
      );

      if (_vendorData!.isEmpty) {
        throw Exception('Vendor not found');
      }

      // Load vendor transactions from transaction_details (keep for financial summary)
      final allTransactions = await ExcelService.instance.getAllTransactionsFromExcel();
      _vendorTransactions = allTransactions
          .where((t) => t['partyName']?.toString().toLowerCase() == widget.vendorName.toLowerCase())
          .toList();

      // Sort transactions by date (newest first)
      _vendorTransactions.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['dateTime'] ?? '');
          final dateB = DateTime.parse(b['dateTime'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      // Load recent purchases grouped by purchaseId from inventory_purchase_details Excel sheet
      final allPurchases = await ExcelService.instance.getGroupedPurchaseHistory();
      _recentPurchases = allPurchases
        .where((p) => p['vendorName']?.toString().toLowerCase() == widget.vendorName.toLowerCase())
        .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          print('🔑 ESC pressed in Vendor Dashboard');
          NavigationService.handleEscapeKey(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.vendorName),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showEditVendorDialog,
              tooltip: 'Edit Vendor',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadVendorData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVendorData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vendor Header Card
                        _buildVendorHeaderCard(),
                        
                        const SizedBox(height: 20),
                        
                        // Credit Usage Section
                        _buildCreditUsageSection(),
                        
                        const SizedBox(height: 20),
                        
                        // Recent Purchases Section
                        _buildRecentPurchasesSection(),
                        
                        const SizedBox(height: 20),
                        
                        // Financial Summary Cards
                        _buildFinancialSummaryCards(),
                        
                        const SizedBox(height: 20),
                        
                        // Payment History Chart
                        _buildPaymentHistorySection(),
                        
                        const SizedBox(height: 20),
                        
                        // Vendor Details Section
                        _buildVendorDetailsSection(),
                        
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildVendorHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.orange[400]!, Colors.orange[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Text(
                  widget.vendorName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      child: Text(
                        widget.vendorName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_vendorData!['email']?.toString().isNotEmpty == true)
                      Container(
                        width: double.infinity,
                        child: Row(
                          children: [
                            const Icon(Icons.email, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _vendorData!['email'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_vendorData!['website']?.toString().isNotEmpty == true)
                      Container(
                        width: double.infinity,
                        child: Row(
                          children: [
                            const Icon(Icons.language, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showWebsiteDialog(_vendorData!['website'].toString()),
                                child: Text(
                                  _vendorData!['website'].toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_vendorData!['phone']?.toString().isNotEmpty == true) ...[
                            const Icon(Icons.phone, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _vendorData!['phone'].toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_vendorData!['city']?.toString().isNotEmpty == true) ...[
                            const Icon(Icons.location_city, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _vendorData!['city'].toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditUsageSection() {
    final currentCredit = _vendorData!['currentCredit'] as double? ?? 0.0;
    final maxCredit = _vendorData!['maximumCredit'] as double? ?? 0.0;
    final availableCredit = maxCredit - currentCredit;
    final creditUtilization = maxCredit > 0 ? (currentCredit / maxCredit) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.orange[600], size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Credit Usage',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (maxCredit <= 0) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      const Text('No credit limit set for this vendor'),
                    ],
                  ),
                ),
              ] else ...[
                // Credit Usage Display (No Pie Chart)
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreditDetailRow(
                        'Used Credit', 
                        'BHD ${currentCredit.toStringAsFixed(2)}',
                        Colors.orange[600]!,
                      ),
                      const SizedBox(height: 12),
                      _buildCreditDetailRow(
                        'Available Credit', 
                        'BHD ${availableCredit.toStringAsFixed(2)}',
                        Colors.green[600]!,
                      ),
                      const SizedBox(height: 12),
                      _buildCreditDetailRow(
                        'Credit Limit', 
                        'BHD ${maxCredit.toStringAsFixed(2)}',
                        Colors.blue[600]!,
                      ),
                      const SizedBox(height: 16),
                      
                      // Credit Utilization Bar
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Utilization', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text('${creditUtilization.toStringAsFixed(1)}%'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: creditUtilization / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                creditUtilization > 80 ? Colors.red : 
                                creditUtilization > 60 ? Colors.orange : Colors.green,
                              ),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditDetailRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPurchasesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.orange[600], size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Recent Purchases',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_recentPurchases.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _showAllPurchases();
                      },
                      child: const Text('View All'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_recentPurchases.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No inventory purchases found for this vendor',
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentPurchases.take(5).length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final purchase = _recentPurchases[index];
                    final items = purchase['items'] as List<dynamic>? ?? [];
                    final itemsOverview = items.map((item) => '${item['itemName']} (${item['quantity']})').join(', ');
                    final purchaseId = purchase['purchaseId']?.toString() ?? '';
                    final date = purchase['date']?.toString() ?? '';
                    final paymentStatus = purchase['paymentStatus']?.toString() ?? '';
                    final totalAmount = purchase['totalAmount'] as double? ?? 0.0;
                    return Container(
                      width: double.infinity,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Icon(
                            Icons.inventory,
                            color: Colors.orange[600],
                          ),
                        ),
                        title: Container(
                          width: double.infinity,
                          child: Text(
                            'Purchase ID: $purchaseId',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        subtitle: Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: $date', 
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                              Text('Items: $itemsOverview', 
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                              Text('Status: $paymentStatus', 
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                        trailing: Text(
                          'BHD ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCards() {
    final currentCredit = _vendorData!['currentCredit'] as double? ?? 0.0;
    
    // Calculate total purchase amount from inventory purchases
    final totalPurchaseAmount = _recentPurchases.fold<double>(0.0, (sum, purchase) {
      final totalCost = purchase['totalCost'] as double? ?? 0.0;
      final quantity = purchase['quantity'] as double? ?? 0.0;
      final unitCost = purchase['unitCost'] as double? ?? 0.0;
      
      // Use totalCost if available, otherwise calculate from quantity * unitCost
      final purchaseAmount = totalCost > 0 ? totalCost : (quantity * unitCost);
      return sum + purchaseAmount;
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Total Purchase Amount
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, size: 32, color: Colors.green[600]),
                    const SizedBox(height: 8),
                    Text(
                      'BHD ${totalPurchaseAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Total Purchases',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Purchase Count
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt, size: 32, color: Colors.blue[600]),
                    const SizedBox(height: 8),
                    Text(
                      '${_recentPurchases.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Purchase Orders',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Outstanding Balance
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance, size: 32, color: Colors.red[600]),
                    const SizedBox(height: 8),
                    Text(
                      'BHD ${currentCredit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Outstanding',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Add Pay Credit button
                    if (currentCredit > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPayCreditDialog(),
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Pay Credit', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: Colors.orange[600], size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Timeline',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                height: 200,
                child: _vendorTransactions.isEmpty
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          child: Text(
                            'No payment history available',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 60),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _generateChartSpots(),
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[600], size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Vendor Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildDetailRow('Email', _vendorData!['email']),
              _buildDetailRow('Phone', _vendorData!['phone']),
              _buildDetailRow('Website', _vendorData!['website']),
              _buildDetailRow('Address', _vendorData!['address']),
              _buildDetailRow('City', _vendorData!['city']),
              _buildDetailRow('Country', _vendorData!['country']),
              _buildDetailRow('VAT Number', _vendorData!['vatNumber']),
              _buildDetailRow('Status', _vendorData!['status']),
              _buildDetailRow('Notes', _vendorData!['notes']),
              if (_vendorData!['lastPurchaseDate']?.toString().isNotEmpty == true)
                _buildDetailRow('Last Purchase', _vendorData!['lastPurchaseDate']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
              textAlign: TextAlign.start,
            ),
          ),
          Expanded(
            child: label == 'Website' && value.toString().isNotEmpty
                ? GestureDetector(
                    onTap: () => _showWebsiteDialog(value.toString()),
                    child: Text(
                      value.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  )
                : Text(
                    value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.start,
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method for purchase date formatting
  String _formatPurchaseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown date';
    
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateStr;
    }
  }

  List<FlSpot> _generateChartSpots() {
    // Generate spots for the chart based on transaction history
    final expenseTransactions = _vendorTransactions
        .where((t) => t['flowType']?.toString().toLowerCase() == 'expense')
        .toList();
    
    if (expenseTransactions.isEmpty) return [];
    
    List<FlSpot> spots = [];
    for (int i = 0; i < expenseTransactions.length && i < 10; i++) {
      final amount = double.tryParse(expenseTransactions[i]['amount']?.toString() ?? '0') ?? 0.0;
      spots.add(FlSpot(i.toDouble(), amount));
    }
    
    return spots.reversed.toList(); // Reverse to show chronological order
  }

  void _showPayCreditDialog() {
    final currentCredit = _vendorData!['currentCredit'] as double? ?? 0.0;
    
    // Reset form
    _paymentAmountController.text = currentCredit.toStringAsFixed(2);
    _paymentReferenceController.clear();
    _paymentNotesController.clear();
    _selectedPaymentMethod = 'Cash';
    _selectedPaymentDate = DateTime.now();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Pay Vendor Credit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(24),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: Colors.orange[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Vendor: ${widget.vendorName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Outstanding Credit: BHD ${currentCredit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Payment Amount
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _paymentAmountController,
                        decoration: InputDecoration(
                          labelText: 'Payment Amount *',
                          prefixText: 'BHD ',
                          prefixIcon: const Icon(Icons.attach_money, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0.0;
                          if (amount > currentCredit) {
                            setDialogState(() {
                              _paymentAmountController.text = currentCredit.toStringAsFixed(2);
                              _paymentAmountController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _paymentAmountController.text.length),
                              );
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          _paymentAmountController.text = currentCredit.toStringAsFixed(2);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Pay All'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Payment Method and Date Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: const Icon(Icons.payment, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _paymentMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedPaymentDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _selectedPaymentDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Payment Date',
                            prefixIcon: const Icon(Icons.calendar_today, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            '${_selectedPaymentDate.day}/${_selectedPaymentDate.month}/${_selectedPaymentDate.year}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Reference Number
                TextFormField(
                  controller: _paymentReferenceController,
                  decoration: InputDecoration(
                    labelText: 'Reference Number',
                    hintText: 'Check number, transaction ID, etc.',
                    prefixIcon: const Icon(Icons.receipt_long, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  controller: _paymentNotesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Payment details, remarks, etc.',
                    prefixIcon: const Icon(Icons.note, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessingPayment ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingPayment ? null : () => _processCreditPayment(context),
                    icon: _isProcessingPayment 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment, size: 18),
                    label: Text(_isProcessingPayment ? 'Processing...' : 'Process Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add the credit payment processing method
  Future<void> _processCreditPayment(BuildContext dialogContext) async {
    final paymentAmount = double.tryParse(_paymentAmountController.text) ?? 0.0;
    final currentCredit = _vendorData!['currentCredit'] as double? ?? 0.0;
    
    if (paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount')),
      );
      return;
    }
    
    if (paymentAmount > currentCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount cannot exceed outstanding credit')),
      );
      return;
    }
    
    setState(() {
      _isProcessingPayment = true;
    });
    
    try {
      final newCreditBalance = currentCredit - paymentAmount;
      
      // Generate transaction ID
      final transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      
      // Save transaction to Excel
      await ExcelService.instance.saveTransactionToExcel(
        transactionType: 'supplier_payment',
        partyName: widget.vendorName,
        amount: -paymentAmount, // Negative because it's money going out
        description: 'Credit payment to ${widget.vendorName}',
        reference: _paymentReferenceController.text.trim().isEmpty 
            ? transactionId 
            : _paymentReferenceController.text.trim(),
        category: 'Vendor Payment',
        transactionDate: _selectedPaymentDate,
      );
      
      // Update vendor credit balance (subtract payment from credit)
      await ExcelService.instance.updateVendorCredit(widget.vendorName, paymentAmount, 'subtract');
      
      // Update local vendor data
      setState(() {
        _vendorData!['currentCredit'] = newCreditBalance;
        _isProcessingPayment = false;
      });
      
      // Close dialog
      Navigator.pop(dialogContext);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of BHD ${paymentAmount.toStringAsFixed(2)} processed successfully'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Reload data to refresh the display
      await _loadVendorData();
      
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _showAllPurchases() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Purchases - ${widget.vendorName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _recentPurchases.length,
            itemBuilder: (context, index) {
              final purchase = _recentPurchases[index];
              final totalCost = purchase['totalCost'] as double? ?? 0.0;
              final quantity = purchase['quantity'] as double? ?? 0.0;
              final unitCost = purchase['unitCost'] as double? ?? 0.0;
              final unit = purchase['unit']?.toString() ?? 'pcs';
              
              // Calculate total if not provided
              final displayTotal = totalCost > 0 ? totalCost : (quantity * unitCost);
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(
                    Icons.inventory,
                    color: Colors.orange[600],
                  ),
                ),
                title: Text(purchase['itemName']?.toString() ?? 'Unknown Item'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty: ${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit'),
                    Text('Unit Cost: BHD ${unitCost.toStringAsFixed(3)}'),
                    if (purchase['invoiceNumber']?.toString().isNotEmpty == true)
                      Text('Invoice: ${purchase['invoiceNumber']}'),
                    Text(_formatPurchaseDate(purchase['purchaseDate'])),
                  ],
                ),
                trailing: Text(
                  'BHD ${displayTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditVendorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vendor'),
        content: const Text('Edit vendor functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWebsiteDialog(String website) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.language, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('Vendor Website'),
          ],
        ),
        content: Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Website URL:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                website,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Copy the URL above to open it in your browser',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _paymentAmountController.dispose();
    _paymentReferenceController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }
}
