import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/excel_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _excelService = ExcelService();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _paymentReceived = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, income, expense, payments, expenses_only
  String _selectedCategory = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data: transactions, payments, and expenses
      final transactions = await _excelService.loadTransactionsFromExcel();
      final payments = await _excelService.loadPaymentReceivedFromExcel();
      final expenses = await _excelService.loadExpensesFromExcel();
      
      setState(() {
        _transactions = transactions;
        _paymentReceived = payments;
        _expenses = expenses;
        _filteredTransactions = transactions;
        _isLoading = false;
      });
      _applyFilters();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      List<Map<String, dynamic>> allData = [];
      
      // Add transactions data
      if (_selectedFilter == 'all' || _selectedFilter == 'income' || _selectedFilter == 'expense') {
        allData.addAll(_transactions);
      }
      
      // Add payment received data as transactions if payments filter is selected
      if (_selectedFilter == 'all' || _selectedFilter == 'payments') {
        final paymentTransactions = _paymentReceived.map((payment) {
          return {
            'transactionId': 'PAY_${payment['saleId'] ?? ''}',
            'partyName': payment['customerName'] ?? 'Unknown',
            'transactionType': 'payment_received',
            'amount': double.tryParse(payment['totalSellingPrice']?.toString() ?? '0') ?? 0.0,
            'category': 'Payment Received',
            'description': 'Payment received for Sale ID: ${payment['saleId'] ?? ''}',
            'reference': payment['saleId']?.toString() ?? '',
            'date': DateTime.tryParse(payment['paymentDate']?.toString() ?? '') ?? DateTime.now(),
            'profit': double.tryParse(payment['totalProfit']?.toString() ?? '0') ?? 0.0,
          };
        }).toList();
        allData.addAll(paymentTransactions);
      }
      
      // Add expenses data as transactions if expenses filter is selected
      if (_selectedFilter == 'all' || _selectedFilter == 'expense' || _selectedFilter == 'expenses_only') {
        final expenseTransactions = _expenses.map((expense) {
          return {
            'transactionId': expense['expenseId'] ?? '',
            'partyName': expense['vendorName']?.toString().isNotEmpty == true 
                ? expense['vendorName'] 
                : 'Business Expense',
            'transactionType': 'expense',
            'amount': -(double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0), // Negative for expenses
            'category': expense['category'] ?? 'Expense',
            'description': expense['description'] ?? '',
            'reference': expense['reference']?.toString() ?? '',
            'date': DateTime.tryParse('${expense['expenseDate'] ?? ''} 00:00:00') ?? DateTime.now(),
            'paymentMethod': expense['paymentMethod'] ?? '',
          };
        }).toList();
        allData.addAll(expenseTransactions);
      }
      
      _filteredTransactions = allData.where((transaction) {
        final amount = transaction['amount'] as double? ?? 0.0;
        final category = transaction['category']?.toString().toLowerCase() ?? '';
        
        // Filter by income/expense/payments
        bool passesTypeFilter = true;
        if (_selectedFilter == 'income' && amount <= 0) passesTypeFilter = false;
        if (_selectedFilter == 'expense' && amount >= 0) passesTypeFilter = false;
        if (_selectedFilter == 'expenses_only' && amount >= 0) passesTypeFilter = false;
        if (_selectedFilter == 'payments' && !category.contains('payment')) passesTypeFilter = false;
        
        // Filter by category
        bool passesCategoryFilter = true;
        if (_selectedCategory != 'all' && !category.contains(_selectedCategory.toLowerCase())) {
          passesCategoryFilter = false;
        }
        
        return passesTypeFilter && passesCategoryFilter;
      }).toList();
      
      // Sort by date (newest first)
      _filteredTransactions.sort((a, b) {
        final dateA = a['date'] as DateTime? ?? DateTime.now();
        final dateB = b['date'] as DateTime? ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    });
  }

  Widget _buildSummaryCards() {
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double salesRevenue = 0.0;
    double paymentsReceived = 0.0;
    double businessExpenses = 0.0;
    int salesCount = 0;
    int paymentsCount = 0;
    int expensesCount = 0;
    
    // Calculate from transactions
    for (final transaction in _transactions) {
      final amount = transaction['amount'] as double? ?? 0.0;
      final category = transaction['category']?.toString().toLowerCase() ?? '';
      
      if (amount > 0) {
        totalIncome += amount;
        if (category.contains('sales')) {
          salesRevenue += amount;
          salesCount++;
        }
      } else {
        totalExpense += amount.abs();
      }
    }
    
    // Calculate from payment received
    for (final payment in _paymentReceived) {
      final amount = double.tryParse(payment['totalSellingPrice']?.toString() ?? '0') ?? 0.0;
      paymentsReceived += amount;
      paymentsCount++;
    }
    
    // Calculate from expenses
    for (final expense in _expenses) {
      final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
      businessExpenses += amount;
      expensesCount++;
    }
    
    final netProfit = totalIncome - totalExpense;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Sales Revenue',
                amount: salesRevenue,
                subtitle: '$salesCount sales',
                color: Colors.green,
                icon: Icons.point_of_sale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Payments Received',
                amount: paymentsReceived,
                subtitle: '$paymentsCount payments',
                color: Colors.teal,
                icon: Icons.payment,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Business Expenses',
                amount: businessExpenses,
                subtitle: '$expensesCount expenses',
                color: Colors.orange,
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Expenses',
                amount: totalExpense,
                subtitle: 'All costs',
                color: Colors.red,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Net Profit',
                amount: netProfit,
                subtitle: 'Income - Expenses',
                color: netProfit >= 0 ? Colors.purple : Colors.red,
                icon: Icons.account_balance,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(3)} BHD',
              style: TextStyle(
                fontSize: 18,
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
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Type', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Transactions')),
                          DropdownMenuItem(value: 'income', child: Text('Income Only')),
                          DropdownMenuItem(value: 'expense', child: Text('Expenses Only')),
                          DropdownMenuItem(value: 'payments', child: Text('Payments Received')),
                          DropdownMenuItem(value: 'expenses_only', child: Text('Business Expenses')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value ?? 'all';
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Categories')),
                          DropdownMenuItem(value: 'sales', child: Text('Sales Revenue')),
                          DropdownMenuItem(value: 'payment', child: Text('Payment Received')),
                          DropdownMenuItem(value: 'expense', child: Text('Business Expenses')),
                          DropdownMenuItem(value: 'inventory', child: Text('Inventory Purchase')),
                          DropdownMenuItem(value: 'salary', child: Text('Salary')),
                          DropdownMenuItem(value: 'customer', child: Text('Customer Payment')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? 'all';
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transactions will appear here when you make sales or purchases',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          return _buildTransactionTile(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] as double? ?? 0.0;
    final isIncome = amount > 0;
    final date = transaction['date'] as DateTime? ?? DateTime.now();
    final partyName = transaction['partyName']?.toString() ?? 'Unknown';
    final description = transaction['description']?.toString() ?? '';
    final category = transaction['category']?.toString() ?? '';
    final reference = transaction['reference']?.toString() ?? '';
    final transactionType = transaction['transactionType']?.toString() ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        child: Icon(
          _getTransactionIcon(transactionType),
          color: isIncome ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        partyName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (category.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      color: isIncome ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncome ? '+' : ''}${amount.toStringAsFixed(3)} BHD',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          if (reference.isNotEmpty)
            Text(
              reference,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      onTap: () => _showTransactionDetails(transaction),
    );
  }

  IconData _getTransactionIcon(String transactionType) {
    switch (transactionType.toLowerCase()) {
      case 'sale':
        return Icons.point_of_sale;
      case 'purchase':
        return Icons.shopping_cart;
      case 'salary':
        return Icons.person;
      case 'payment_received':
        return Icons.payment;
      case 'expense':
        return Icons.receipt_long;
      default:
        return Icons.receipt;
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 8),
            const Text('Transaction Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Transaction ID', transaction['transactionId']?.toString() ?? 'N/A'),
              _buildDetailRow('Party Name', transaction['partyName']?.toString() ?? 'N/A'),
              _buildDetailRow('Type', transaction['transactionType']?.toString() ?? 'N/A'),
              _buildDetailRow('Amount', '${transaction['amount']?.toStringAsFixed(3) ?? '0.000'} BHD'),
              _buildDetailRow('Category', transaction['category']?.toString() ?? 'N/A'),
              _buildDetailRow('Description', transaction['description']?.toString() ?? 'N/A'),
              _buildDetailRow('Reference', transaction['reference']?.toString() ?? 'N/A'),
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy HH:mm').format(
                transaction['date'] as DateTime? ?? DateTime.now()
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
        title: const Text('All Transactions'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Syncing sales to transactions...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              await _loadTransactions();
            },
            tooltip: 'Sync Sales to Transactions',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(),
            
            const SizedBox(height: 20),
            
            // Filter Section
            _buildFilterSection(),
            
            const SizedBox(height: 20),
            
            // Transactions List
            Row(
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredTransactions.length} transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }
}
