import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/account.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Transaction> _ledgerEntries = [];
  String _selectedAccount = 'All Accounts';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadMockLedgerData();
  }

  void _loadMockLedgerData() {
    // Mock ledger data for demonstration
    _ledgerEntries = [
      Transaction(
        id: 'txn_001',
        date: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Order Payment - ORD-001',
        amount: 85.00,
        type: 'Payment',
        reference: 'INV-001',
      ),
      Transaction(
        id: 'txn_002',
        date: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Material Purchase',
        amount: -45.00,
        type: 'Expense',
        reference: 'PO-001',
      ),
      Transaction(
        id: 'txn_003',
        date: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Order Payment - ORD-002',
        amount: 120.00,
        type: 'Payment',
        reference: 'INV-002',
      ),
      Transaction(
        id: 'txn_004',
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Fabric Purchase',
        amount: -65.00,
        type: 'Expense',
        reference: 'PO-002',
      ),
    ];
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  List<Transaction> get _filteredEntries {
    List<Transaction> filtered = _ledgerEntries;
    
    if (_selectedDateRange != null) {
      filtered = filtered.where((entry) {
        return entry.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               entry.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    return filtered;
  }

  double get _totalDebits {
    return _filteredEntries
        .where((entry) => entry.isDebit)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get _totalCredits {
    return _filteredEntries
        .where((entry) => entry.isCredit)
        .fold(0.0, (sum, entry) => sum + entry.amount.abs());
  }

  double get _netBalance {
    return _totalDebits - _totalCredits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('General Ledger'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All Accounts', child: Text('All Accounts')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                          DropdownMenuItem(value: 'Customers', child: Text('Customers')),
                          DropdownMenuItem(value: 'Suppliers', child: Text('Suppliers')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectDateRange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _selectedDateRange == null
                              ? 'Select Date Range'
                              : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearDateFilter,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear date filter',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Summary Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Debits',
                    'BHD ${_totalDebits.toStringAsFixed(3)}',
                    Colors.green[600]!,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Credits',
                    'BHD ${_totalCredits.toStringAsFixed(3)}',
                    Colors.red[600]!,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Net Balance',
                    'BHD ${_netBalance.toStringAsFixed(3)}',
                    _netBalance >= 0 ? Colors.green[600]! : Colors.red[600]!,
                    _netBalance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Ledger Entries
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return _buildLedgerEntry(entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerEntry(Transaction entry) {
    final isDebit = entry.isDebit;
    final color = isDebit ? Colors.green[600]! : Colors.red[600]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isDebit ? Icons.add : Icons.remove,
            color: color,
          ),
        ),
        title: Text(
          entry.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${entry.date.day}/${entry.date.month}/${entry.date.year}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (entry.reference.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Ref: ${entry.reference}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebit ? '+' : '-'}BHD ${entry.amount.abs().toStringAsFixed(3)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.type,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
