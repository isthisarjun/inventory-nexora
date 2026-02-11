import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/account.dart';

class CustomerAccountsScreen extends StatefulWidget {
  const CustomerAccountsScreen({super.key});

  @override
  State<CustomerAccountsScreen> createState() => _CustomerAccountsScreenState();
}

class _CustomerAccountsScreenState extends State<CustomerAccountsScreen> {
  List<Account> _customers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    // Mock customer data
    _customers = [
      Account(
        id: 'cust_001',
        name: 'Ahmed Al-Mansouri',
        type: 'customer',
        balance: 150.00,
        email: 'ahmed@email.com',
        phone: '+973 1234 5678',
        address: 'Manama, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 5)),
        transactions: [
          Transaction(
            id: 'txn_001',
            date: DateTime.now().subtract(const Duration(days: 5)),
            description: 'Invoice #INV-001 - Custom Suit',
            amount: 200.00,
            type: 'invoice',
            reference: 'INV-001',
          ),
          Transaction(
            id: 'txn_002',
            date: DateTime.now().subtract(const Duration(days: 3)),
            description: 'Payment received',
            amount: -50.00,
            type: 'payment',
            reference: 'PAY-001',
          ),
        ],
      ),
      Account(
        id: 'cust_002',
        name: 'Fatima Al-Khalifa',
        type: 'customer',
        balance: 0.00,
        email: 'fatima@email.com',
        phone: '+973 2345 6789',
        address: 'Riffa, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 10)),
        transactions: [
          Transaction(
            id: 'txn_003',
            date: DateTime.now().subtract(const Duration(days: 10)),
            description: 'Invoice #INV-002 - Formal Dress',
            amount: 180.00,
            type: 'invoice',
            reference: 'INV-002',
          ),
          Transaction(
            id: 'txn_004',
            date: DateTime.now().subtract(const Duration(days: 8)),
            description: 'Payment received - Full',
            amount: -180.00,
            type: 'payment',
            reference: 'PAY-002',
          ),
        ],
      ),
      Account(
        id: 'cust_003',
        name: 'Mohammed Al-Thani',
        type: 'customer',
        balance: 320.00,
        email: 'mohammed@email.com',
        phone: '+973 3456 7890',
        address: 'Saar, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 2)),
        transactions: [
          Transaction(
            id: 'txn_005',
            date: DateTime.now().subtract(const Duration(days: 2)),
            description: 'Invoice #INV-003 - Wedding Collection',
            amount: 320.00,
            type: 'invoice',
            reference: 'INV-003',
          ),
        ],
      ),
    ];
  }

  List<Account> get _filteredCustomers {
    if (_searchQuery.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalOutstanding = _customers.fold(0.0, (sum, customer) => sum + customer.debitBalance);
    final customersWithBalance = _customers.where((c) => c.hasOutstandingBalance).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
          tooltip: 'Back to Accounts',
        ),
        title: const Text('Customer Accounts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.go('/add-customer?fromAccounts=true'),
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Outstanding',
                    'BHD ${totalOutstanding.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Outstanding Accounts',
                    '$customersWithBalance/${_customers.length}',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Customer list
          Expanded(
            child: _filteredCustomers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return _buildCustomerCard(customer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Account customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: customer.hasOutstandingBalance ? Colors.red[100] : Colors.green[100],
          child: Icon(
            Icons.person,
            color: customer.hasOutstandingBalance ? Colors.red[700] : Colors.green[700],
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.email),
            Text(customer.phone),
            if (customer.hasOutstandingBalance)
              Text(
                'Outstanding: BHD ${customer.debitBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, customer),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Customer')),
            const PopupMenuItem(value: 'payment', child: Text('Record Payment')),
            const PopupMenuItem(value: 'invoice', child: Text('Create Invoice')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Customer')),
          ],
        ),
        onTap: () => _showCustomerDetails(customer),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add customers to track their accounts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/add-customer?fromAccounts=true'),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Account customer) {
    switch (action) {
      case 'view':
        _showCustomerDetails(customer);
        break;
      case 'edit':
        _editCustomer(customer);
        break;
      case 'payment':
        _recordPayment(customer);
        break;
      case 'invoice':
        _createInvoice(customer);
        break;
      case 'delete':
        _deleteCustomer(customer);
        break;
    }
  }

  void _showCustomerDetails(Account customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} - Account Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email:', customer.email),
              _buildDetailRow('Phone:', customer.phone),
              _buildDetailRow('Address:', customer.address),
              _buildDetailRow('Balance:', 'BHD ${customer.balance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'Recent Transactions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...customer.transactions.take(3).map((txn) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        txn.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      'BHD ${txn.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: txn.amount > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editCustomer(Account customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit customer functionality will be implemented')),
    );
  }

  void _recordPayment(Account customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record payment functionality will be implemented')),
    );
  }

  void _createInvoice(Account customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create invoice functionality will be implemented')),
    );
  }

  void _deleteCustomer(Account customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality will be implemented')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
