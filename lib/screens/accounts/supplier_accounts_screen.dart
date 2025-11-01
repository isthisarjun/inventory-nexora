import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/account.dart';

class SupplierAccountsScreen extends StatefulWidget {
  const SupplierAccountsScreen({super.key});

  @override
  State<SupplierAccountsScreen> createState() => _SupplierAccountsScreenState();
}

class _SupplierAccountsScreenState extends State<SupplierAccountsScreen> {
  List<Account> _suppliers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() {
    // Mock supplier data
    _suppliers = [
      Account(
        id: 'supp_001',
        name: 'Bahrain Fabrics Co.',
        type: 'supplier',
        balance: -250.00,
        email: 'info@bahrainfabrics.com',
        phone: '+973 3456 7890',
        address: 'Muharraq, Bahrain',
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 3)),
        transactions: [
          Transaction(
            id: 'txn_101',
            date: DateTime.now().subtract(const Duration(days: 3)),
            description: 'Purchase Order #PO-001 - Cotton Fabric',
            amount: -250.00,
            type: 'purchase',
            reference: 'PO-001',
          ),
        ],
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
        transactions: [
          Transaction(
            id: 'txn_102',
            date: DateTime.now().subtract(const Duration(days: 7)),
            description: 'Purchase Order #PO-002 - Silk Materials',
            amount: -150.00,
            type: 'purchase',
            reference: 'PO-002',
          ),
          Transaction(
            id: 'txn_103',
            date: DateTime.now().subtract(const Duration(days: 5)),
            description: 'Payment made - Partial',
            amount: 75.00,
            type: 'payment',
            reference: 'PAY-101',
          ),
        ],
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
        transactions: [
          Transaction(
            id: 'txn_104',
            date: DateTime.now().subtract(const Duration(days: 15)),
            description: 'Purchase Order #PO-003 - Buttons & Zippers',
            amount: -120.00,
            type: 'purchase',
            reference: 'PO-003',
          ),
          Transaction(
            id: 'txn_105',
            date: DateTime.now().subtract(const Duration(days: 12)),
            description: 'Payment made - Full',
            amount: 120.00,
            type: 'payment',
            reference: 'PAY-102',
          ),
        ],
      ),
    ];
  }

  List<Account> get _filteredSuppliers {
    if (_searchQuery.isEmpty) {
      return _suppliers;
    }
    return _suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             supplier.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             supplier.phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalPayable = _suppliers.fold(0.0, (sum, supplier) => sum + supplier.creditBalance);
    final suppliersWithBalance = _suppliers.where((s) => s.hasOutstandingBalance).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
          tooltip: 'Back to Accounts',
        ),
        title: const Text('Supplier Accounts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.store_mall_directory),
            onPressed: () => context.go('/vendors'),
            tooltip: 'Manage Vendors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Payable',
                    'BHD ${totalPayable.toStringAsFixed(2)}',
                    Icons.payment,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Outstanding Accounts',
                    '$suppliersWithBalance/${_suppliers.length}',
                    Icons.store,
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
                hintText: 'Search suppliers...',
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
          
          // Supplier list
          Expanded(
            child: _filteredSuppliers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = _filteredSuppliers[index];
                      return _buildSupplierCard(supplier);
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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

  Widget _buildSupplierCard(Account supplier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: supplier.hasOutstandingBalance ? Colors.orange[100] : Colors.green[100],
          child: Icon(
            Icons.store,
            color: supplier.hasOutstandingBalance ? Colors.orange[700] : Colors.green[700],
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(supplier.email),
            Text(supplier.phone),
            if (supplier.hasOutstandingBalance)
              Text(
                'Payable: BHD ${supplier.creditBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, supplier),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Supplier')),
            const PopupMenuItem(value: 'payment', child: Text('Record Payment')),
            const PopupMenuItem(value: 'purchase', child: Text('Create Purchase Order')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Supplier')),
          ],
        ),
        onTap: () => _showSupplierDetails(supplier),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add suppliers to track their accounts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/vendors'),
            icon: const Icon(Icons.store_mall_directory),
            label: const Text('Manage Vendors'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Account supplier) {
    switch (action) {
      case 'view':
        _showSupplierDetails(supplier);
        break;
      case 'edit':
        _editSupplier(supplier);
        break;
      case 'payment':
        _recordPayment(supplier);
        break;
      case 'purchase':
        _createPurchaseOrder(supplier);
        break;
      case 'delete':
        _deleteSupplier(supplier);
        break;
    }
  }

  void _showSupplierDetails(Account supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${supplier.name} - Account Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email:', supplier.email),
              _buildDetailRow('Phone:', supplier.phone),
              _buildDetailRow('Address:', supplier.address),
              _buildDetailRow('Balance:', 'BHD ${supplier.balance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'Recent Transactions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...supplier.transactions.take(3).map((txn) => Padding(
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
                        color: txn.amount < 0 ? Colors.red : Colors.green,
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

  void _editSupplier(Account supplier) {
    context.go('/vendors'); // Navigate to vendor management
  }

  void _recordPayment(Account supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record payment functionality will be implemented')),
    );
  }

  void _createPurchaseOrder(Account supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create purchase order functionality will be implemented')),
    );
  }

  void _deleteSupplier(Account supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
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
