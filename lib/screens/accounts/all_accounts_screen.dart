import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/account.dart';

class AllAccountsScreen extends StatefulWidget {
  const AllAccountsScreen({super.key});

  @override
  State<AllAccountsScreen> createState() => _AllAccountsScreenState();
}

class _AllAccountsScreenState extends State<AllAccountsScreen> with SingleTickerProviderStateMixin {
  List<Account> _allAccounts = [];
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAllAccounts() {
    // Mock combined account data
    _allAccounts = [
      // Customers
      Account(
        id: 'cust_001',
        name: 'Ahmed Al-Mansouri',
        type: 'customer',
        balance: 150.00,
        email: 'ahmed@email.com',
        phone: '+973 1234 5678',
        address: 'Manama, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 5)),
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
      ),
      // Suppliers
      Account(
        id: 'supp_001',
        name: 'Bahrain Fabrics Co.',
        type: 'supplier',
        balance: -250.00,
        email: 'info@bahrainfabrics.com',
        phone: '+973 3456 7890',
        address: 'Muharraq, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Account(
        id: 'supp_002',
        name: 'Gulf Textile Trading',
        type: 'supplier',
        balance: -75.00,
        email: 'sales@gulftextile.com',
        phone: '+973 4567 8901',
        address: 'Isa Town, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Account(
        id: 'supp_003',
        name: 'Premium Buttons & Accessories',
        type: 'supplier',
        balance: 0.00,
        email: 'info@premiumbuttons.com',
        phone: '+973 5678 9012',
        address: 'Hamad Town, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  List<Account> get _filteredAccounts {
    List<Account> filtered = _allAccounts;

    // Apply type filter based on tab
    switch (_tabController.index) {
      case 1: // Customers
        filtered = filtered.where((acc) => acc.isCustomer).toList();
        break;
      case 2: // Suppliers
        filtered = filtered.where((acc) => acc.isSupplier).toList();
        break;
      case 3: // Outstanding
        filtered = filtered.where((acc) => acc.hasOutstandingBalance).toList();
        break;
      // case 0 is 'All' - no filtering
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((account) {
        return account.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               account.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               account.phone.contains(_searchQuery);
      }).toList();
    }

    // Sort by balance (outstanding first, then by amount)
    filtered.sort((a, b) {
      if (a.hasOutstandingBalance && !b.hasOutstandingBalance) return -1;
      if (!a.hasOutstandingBalance && b.hasOutstandingBalance) return 1;
      return b.balance.abs().compareTo(a.balance.abs());
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _allAccounts.where((acc) => acc.isCustomer).toList();
    final suppliers = _allAccounts.where((acc) => acc.isSupplier).toList();
    final totalReceivables = customers.fold(0.0, (sum, acc) => sum + acc.debitBalance);
    final totalPayables = suppliers.fold(0.0, (sum, acc) => sum + acc.creditBalance);
    final outstandingAccounts = _allAccounts.where((acc) => acc.hasOutstandingBalance).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
          tooltip: 'Back to Accounts',
        ),
        title: const Text('All Accounts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Customers'),
            Tab(text: 'Suppliers'),
            Tab(text: 'Outstanding'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Receivables',
                    'BHD ${totalReceivables.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Payables',
                    'BHD ${totalPayables.toStringAsFixed(2)}',
                    Icons.trending_down,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Outstanding',
                    '$outstandingAccounts accounts',
                    Icons.warning,
                    Colors.red,
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
                hintText: 'Search accounts...',
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
          
          // Account list
          Expanded(
            child: _filteredAccounts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _filteredAccounts[index];
                      return _buildAccountCard(account);
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.isCustomer 
              ? (account.hasOutstandingBalance ? Colors.red[100] : Colors.blue[100])
              : (account.hasOutstandingBalance ? Colors.orange[100] : Colors.green[100]),
          child: Icon(
            account.isCustomer ? Icons.person : Icons.store,
            color: account.isCustomer 
                ? (account.hasOutstandingBalance ? Colors.red[700] : Colors.blue[700])
                : (account.hasOutstandingBalance ? Colors.orange[700] : Colors.green[700]),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: account.isCustomer ? Colors.blue[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                account.isCustomer ? 'Customer' : 'Supplier',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: account.isCustomer ? Colors.blue[700] : Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.email,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    account.phone,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (account.hasOutstandingBalance)
                  Text(
                    account.isCustomer 
                        ? 'Due: BHD ${account.debitBalance.toStringAsFixed(2)}'
                        : 'Payable: BHD ${account.creditBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: account.isCustomer ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, account),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Account')),
            if (account.hasOutstandingBalance)
              const PopupMenuItem(value: 'payment', child: Text('Record Payment')),
            PopupMenuItem(
              value: 'transaction',
              child: Text(account.isCustomer ? 'Create Invoice' : 'Create Purchase'),
            ),
          ],
        ),
        onTap: () => _showAccountDetails(account),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    switch (_tabController.index) {
      case 1:
        message = 'No customers found';
        subtitle = 'Add customers to track their accounts';
        icon = Icons.people_outline;
        break;
      case 2:
        message = 'No suppliers found';
        subtitle = 'Add suppliers to track their accounts';
        icon = Icons.store_outlined;
        break;
      case 3:
        message = 'No outstanding accounts';
        subtitle = 'All accounts are settled';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No accounts found';
        subtitle = 'Add customers and suppliers to get started';
        icon = Icons.account_balance_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Account account) {
    switch (action) {
      case 'view':
        _showAccountDetails(account);
        break;
      case 'edit':
        if (account.isCustomer) {
          context.go('/add-customer?customerId=${account.id}');
        } else {
          context.go('/vendors');
        }
        break;
      case 'payment':
        _recordPayment(account);
        break;
      case 'transaction':
        _createTransaction(account);
        break;
    }
  }

  void _showAccountDetails(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.name} - Account Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type:', account.isCustomer ? 'Customer' : 'Supplier'),
              _buildDetailRow('Email:', account.email),
              _buildDetailRow('Phone:', account.phone),
              _buildDetailRow('Address:', account.address),
              _buildDetailRow('Balance:', 'BHD ${account.balance.toStringAsFixed(2)}'),
              _buildDetailRow('Last Transaction:', _formatDate(account.lastTransactionDate)),
              if (account.hasOutstandingBalance) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: account.isCustomer ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.isCustomer 
                        ? 'Outstanding Receivable: BHD ${account.debitBalance.toStringAsFixed(2)}'
                        : 'Outstanding Payable: BHD ${account.creditBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: account.isCustomer ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (account.hasOutstandingBalance)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _recordPayment(account);
              },
              child: const Text('Record Payment'),
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
            width: 100,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _recordPayment(Account account) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record payment functionality will be implemented')),
    );
  }

  void _createTransaction(Account account) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Create ${account.isCustomer ? 'invoice' : 'purchase order'} functionality will be implemented'),
      ),
    );
  }
}
