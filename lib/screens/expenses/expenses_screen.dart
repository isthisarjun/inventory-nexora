import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../services/excel_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _excelService = ExcelService();
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  bool _isLoading = true;
  String? _selectedCategory; // Changed back to single category selection
  String _selectedPaymentMethod = 'all';
  DateTimeRange? _selectedDateRange;
  List<String> _availableCategories = []; // For dialog category selection

  final List<String> _expenseCategories = [
    'Salary',
    'Office Supplies',
    'Marketing',
    'Travel',
    'Utilities',
    'Rent',
    'Equipment',
    'Professional Services',
    'Insurance',
    'Taxes',
    'Maintenance',
    'Other'
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'Debit Card',
    'Check',
    'Online Payment'
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadAvailableCategories();
  }

  Future<void> _loadAvailableCategories() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final categoriesFile = File('${documentsDir.path}/expense_categories.json');
      
      if (await categoriesFile.exists()) {
        final jsonString = await categoriesFile.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          _availableCategories = jsonList.cast<String>();
        });
      } else {
        // Use default categories if file doesn't exist
        setState(() {
          _availableCategories = _expenseCategories;
        });
      }
    } catch (e) {
      print('Error loading available categories: $e');
      setState(() {
        _availableCategories = _expenseCategories;
      });
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all transactions from transaction_details Excel sheet
      final allTransactions = await _excelService.getAllTransactionsFromExcel();
      
      // Filter only expense transactions (Flow Type = "Expense")
      final expenseTransactions = allTransactions.where((transaction) {
        return transaction['flowType']?.toString().toLowerCase() == 'expense';
      }).toList();

      // Convert transaction format to expense format for display
      final expenses = expenseTransactions.map((transaction) {
        return {
          'expenseId': transaction['reference'] ?? transaction['transactionId'],
          'description': transaction['description'] ?? '',
          'vendorName': transaction['partyName'] ?? '',
          'amount': double.tryParse(transaction['amount']?.toString() ?? '0')?.abs() ?? 0.0,
          'category': transaction['category'] ?? 'Other',
          'paymentMethod': 'Unknown', // Not stored in transaction_details
          'expenseDate': transaction['dateTime'] ?? '',
          'reference': transaction['reference'] ?? '',
          'transactionType': transaction['transactionType'] ?? 'expense',
        };
      }).toList();

      // Sort by date (newest first)
      expenses.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['expenseDate'].toString().split(' ')[0]);
          final dateB = DateTime.parse(b['expenseDate'].toString().split(' ')[0]);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _expenses = expenses;
        _filteredExpenses = expenses;
        _isLoading = false;
      });
      
      print('Loaded ${expenses.length} expense transactions from transaction_details');
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        final category = expense['category']?.toString().toLowerCase() ?? '';
        final paymentMethod = expense['paymentMethod']?.toString().toLowerCase() ?? '';
        final expenseDate = DateTime.tryParse('${expense['expenseDate'] ?? ''} 00:00:00');

        // Filter by category - if no category selected, show all
        bool passesCategoryFilter = _selectedCategory == null || 
            category.contains(_selectedCategory!.toLowerCase());

        // Filter by payment method
        bool passesPaymentMethodFilter = _selectedPaymentMethod == 'all' || 
            paymentMethod.contains(_selectedPaymentMethod.toLowerCase());

        // Filter by date range
        bool passesDateFilter = true;
        if (_selectedDateRange != null && expenseDate != null) {
          passesDateFilter = expenseDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              expenseDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
        }

        return passesCategoryFilter && passesPaymentMethodFilter && passesDateFilter;
      }).toList();

      // Sort by date (newest first)
      _filteredExpenses.sort((a, b) {
        final dateA = DateTime.tryParse('${a['expenseDate'] ?? ''} 00:00:00') ?? DateTime.now();
        final dateB = DateTime.tryParse('${b['expenseDate'] ?? ''} 00:00:00') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    });
  }

  Future<void> _showAddExpenseDialog() async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final vendorController = TextEditingController();
    final referenceController = TextEditingController();
    String selectedCategory = _availableCategories.isNotEmpty ? _availableCategories.first : 'Other';
    String selectedPaymentMethod = _paymentMethods.first;
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Add New Expense',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Row 1: Description, Amount
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description *',
                                prefixIcon: const Icon(Icons.description, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: const TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: amountController,
                              decoration: InputDecoration(
                                labelText: 'Amount (BHD) *',
                                prefixIcon: const Icon(Icons.attach_money, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: const TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (double.tryParse(value!) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 2: Category, Payment Method
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category *',
                                prefixIcon: const Icon(Icons.category, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: const TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                              items: _availableCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedPaymentMethod,
                              decoration: InputDecoration(
                                labelText: 'Payment Method *',
                                prefixIcon: const Icon(Icons.payment, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: const TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                              items: _paymentMethods.map((method) {
                                return DropdownMenuItem(
                                  value: method,
                                  child: Text(method, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedPaymentMethod = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 3: Paid To, Reference, Date
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: vendorController,
                              decoration: InputDecoration(
                                labelText: 'Paid To *',
                                prefixIcon: const Icon(Icons.person, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: const TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: referenceController,
                              decoration: InputDecoration(
                                labelText: 'Reference',
                                prefixIcon: const Icon(Icons.receipt, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                labelStyle: const TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  labelStyle: const TextStyle(fontSize: 14),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                await _excelService.saveExpenseToExcel(
                                  expenseDate: selectedDate,
                                  expenseCategory: selectedCategory,
                                  description: descriptionController.text.trim(),
                                  amount: double.parse(amountController.text.trim()),
                                  paymentMethod: selectedPaymentMethod,
                                  vendorName: vendorController.text.trim(),
                                  reference: referenceController.text.trim().isNotEmpty 
                                      ? referenceController.text.trim() 
                                      : null,
                                );
                                Navigator.of(context).pop(true);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving expense: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildSummaryCards() {
    double totalExpenses = 0.0;
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCount = {};

    for (final expense in _filteredExpenses) {
      final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
      final category = expense['category']?.toString() ?? 'Other';
      
      totalExpenses += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_down, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalExpenses.toStringAsFixed(3)} BHD',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  '${_filteredExpenses.length} transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (topCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (topCategories.isNotEmpty)
                Expanded(
                  child: _buildCategorySummaryCard(
                    topCategories[0].key,
                    topCategories[0].value,
                    categoryCount[topCategories[0].key] ?? 0,
                    Colors.orange,
                  ),
                ),
              if (topCategories.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategorySummaryCard(
                    topCategories[1].key,
                    topCategories[1].value,
                    categoryCount[topCategories[1].key] ?? 0,
                    Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySummaryCard(String category, double amount, int count, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCategoryIcon(category), color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${amount.toStringAsFixed(3)} BHD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$count transactions',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.person;
      case 'office supplies':
        return Icons.inventory;
      case 'marketing':
        return Icons.campaign;
      case 'travel':
        return Icons.flight;
      case 'utilities':
        return Icons.electrical_services;
      case 'rent':
        return Icons.home;
      case 'equipment':
        return Icons.computer;
      case 'professional services':
        return Icons.work;
      case 'insurance':
        return Icons.security;
      case 'taxes':
        return Icons.account_balance;
      default:
        return Icons.receipt_long;
    }
  }

  Widget _buildFiltersSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            
            // Compact horizontal filter row
            Row(
              children: [
                // Category Filter - Equal space (1/3)
                Expanded(
                  child: _buildCompactCategoryFilter(),
                ),
                
                const SizedBox(width: 16),
                
                // Payment Method Filter - Equal space (1/3)
                Expanded(
                  child: _buildCompactPaymentMethodFilter(),
                ),
                
                const SizedBox(width: 16),
                
                // Date Range Filter - Equal space (1/3)
                Expanded(
                  child: _buildCompactDateRangeFilter(),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Clear All button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredExpenses.isEmpty) {
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
                'No expenses found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first expense by tapping the + button',
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
        itemCount: _filteredExpenses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final expense = _filteredExpenses[index];
          return _buildExpenseTile(expense);
        },
      ),
    );
  }

  Widget _buildExpenseTile(Map<String, dynamic> expense) {
    final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
    final date = DateTime.tryParse('${expense['expenseDate'] ?? ''} 00:00:00') ?? DateTime.now();
    final description = expense['description']?.toString() ?? '';
    final category = expense['category']?.toString() ?? '';
    final vendor = expense['vendorName']?.toString() ?? '';
    final paymentMethod = expense['paymentMethod']?.toString() ?? '';
    final reference = expense['reference']?.toString() ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withOpacity(0.1),
        child: Icon(
          _getCategoryIcon(category),
          color: Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        description,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vendor.isNotEmpty && vendor != 'N/A')
            Text(
              'Paid to: $vendor',
              style: const TextStyle(fontSize: 14),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  paymentMethod,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
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
            '${amount.toStringAsFixed(3)} BHD',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          if (reference.isNotEmpty && reference != 'N/A')
            Text(
              reference,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      onTap: () => _showExpenseDetails(expense),
    );
  }

  void _showExpenseDetails(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 8),
            const Text('Expense Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Expense ID', expense['expenseId']?.toString() ?? 'N/A'),
              _buildDetailRow('Description', expense['description']?.toString() ?? 'N/A'),
              _buildDetailRow('Amount', '${expense['amount']?.toString() ?? '0'} BHD'),
              _buildDetailRow('Category', expense['category']?.toString() ?? 'N/A'),
              _buildDetailRow('Payment Method', expense['paymentMethod']?.toString() ?? 'N/A'),
              _buildDetailRow('Paid To', expense['vendorName']?.toString() ?? 'N/A'),
              _buildDetailRow('Reference', expense['reference']?.toString() ?? 'N/A'),
              _buildDetailRow('Date', expense['expenseDate']?.toString() ?? 'N/A'),
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
            width: 120,
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
        title: const Text('Expense Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
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
            
            // Filters Section
            _buildFiltersSection(),
            
            const SizedBox(height: 20),
            
            // Expenses List Header
            Row(
              children: [
                const Text(
                  'Expense Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredExpenses.length} expenses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Expenses List
            _buildExpensesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildCompactCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            hint: const Text('All', style: TextStyle(fontSize: 14)),
            isExpanded: true,
            items: [
              // Clear selection option
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Categories', style: TextStyle(fontSize: 14)),
              ),
              
              // Regular categories from expense categories
              ..._expenseCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _applyFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPaymentMethodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPaymentMethod == 'all' ? null : _selectedPaymentMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            hint: const Text('All', style: TextStyle(fontSize: 14)),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Methods', style: TextStyle(fontSize: 14)),
              ),
              ..._paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Row(
                    children: [
                      Icon(_getPaymentMethodIcon(method), size: 16),
                      const SizedBox(width: 4),
                      Text(method, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value ?? 'all';
              });
              _applyFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDateRange == null ? null : 'custom',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            hint: const Text('Select Range', style: TextStyle(fontSize: 14)),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Dates', style: TextStyle(fontSize: 14)),
              ),
              const DropdownMenuItem<String>(
                value: 'today',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 16),
                    SizedBox(width: 4),
                    Text('Today', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const DropdownMenuItem<String>(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 16),
                    SizedBox(width: 4),
                    Text('This Week', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const DropdownMenuItem<String>(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16),
                    SizedBox(width: 4),
                    Text('This Month', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'custom',
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _selectedDateRange == null 
                            ? 'Custom Range...' 
                            : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) async {
              if (value == null) {
                setState(() {
                  _selectedDateRange = null;
                });
                _applyFilters();
              } else if (value == 'today') {
                setState(() {
                  final now = DateTime.now();
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(now.year, now.month, now.day),
                    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
                  );
                });
                _applyFilters();
              } else if (value == 'week') {
                setState(() {
                  final now = DateTime.now();
                  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                  final endOfWeek = startOfWeek.add(const Duration(days: 6));
                  _selectedDateRange = DateTimeRange(
                    start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
                    end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
                  );
                });
                _applyFilters();
              } else if (value == 'month') {
                setState(() {
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  final endOfMonth = DateTime(now.year, now.month + 1, 0);
                  _selectedDateRange = DateTimeRange(
                    start: startOfMonth,
                    end: DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59),
                  );
                });
                _applyFilters();
              } else if (value == 'custom') {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() {
                    _selectedDateRange = picked;
                  });
                  _applyFilters();
                }
              }
            },
          ),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'credit card':
      case 'debit card':
        return Icons.credit_card;
      case 'bank transfer':
        return Icons.account_balance;
      case 'check':
        return Icons.receipt;
      case 'online payment':
        return Icons.computer;
      default:
        return Icons.payment;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedPaymentMethod = 'all';
      _selectedDateRange = null;
    });
    _applyFilters();
  }
}
