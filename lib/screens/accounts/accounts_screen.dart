import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/account.dart';
import '../../services/excel_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> _accounts = [];
  final ExcelService _excelService = ExcelService();
  double _creditReceivables = 0.0;
  double _creditPayables = 0.0;
  bool _isLoadingCreditTotals = false;

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _loadCreditPaymentTotals();
  }

  void _loadMockData() {
    // Mock data for demonstration
    _accounts = [
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
    ];
  }

  Future<void> _loadCreditPaymentTotals() async {
    setState(() {
      _isLoadingCreditTotals = true;
    });

    try {
      final transactions = await _excelService.loadTransactionsFromExcel();

      double receivables = 0.0;
      double payables = 0.0;

      for (final transaction in transactions) {
        final type = transaction['transactionType']?.toString().toLowerCase() ?? '';
        final category = transaction['category']?.toString().toLowerCase() ?? '';
        final flowType = transaction['flowType']?.toString().toLowerCase() ?? '';
        final amount = (transaction['amount'] as double? ?? 0.0).abs();

        final isCreditPayment = type.contains('payment') || category.contains('payment');
        if (!isCreditPayment) continue;

        final isIncome = flowType == 'income' || (transaction['amount'] as double? ?? 0.0) > 0;
        if (isIncome) {
          receivables += amount;
        } else {
          payables += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _creditReceivables = receivables;
        _creditPayables = payables;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creditReceivables = 0.0;
        _creditPayables = 0.0;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingCreditTotals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = _accounts.where((account) => account.isCustomer).toList();
    final suppliers = _accounts.where((account) => account.isSupplier).toList();
    
    final totalDebtors = _creditReceivables;
    final totalCreditors = _creditPayables;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        title: const Text('Accounts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () => context.go('/vat-filing'),
            tooltip: 'VAT Filing',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with summary
            _buildSummaryCards(totalDebtors, totalCreditors),
            
            const SizedBox(height: 24),
            
            // Main Account Sections
            const Text(
              'Account Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildAccountSection(
              title: 'Customers/Debtors',
              subtitle: '${customers.length} customers • BHD ${totalDebtors.toStringAsFixed(2)} outstanding',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => context.go('/customer-accounts'),
            ),
            
            const SizedBox(height: 12),
            
            _buildAccountSection(
              title: 'Suppliers/Creditors',
              subtitle: '${suppliers.length} suppliers • BHD ${totalCreditors.toStringAsFixed(2)} payable',
              icon: Icons.store,
              color: Colors.orange,
              onTap: () => context.go('/supplier-accounts'),
            ),
            
            const SizedBox(height: 12),
            
            _buildAccountSection(
              title: 'All Accounts',
              subtitle: '${_accounts.length} total accounts',
              icon: Icons.account_balance,
              color: Colors.green,
              onTap: () => context.go('/all-accounts'),
            ),
            
            const SizedBox(height: 32),
            
            // Accounting Reports Section
            const Text(
              'Accounting Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildReportTile(
                    title: 'Ledger',
                    subtitle: 'View account ledger',
                    icon: Icons.book,
                    color: Colors.purple,
                    onTap: () => context.go('/ledger'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Navigation Section
            const Text(
              'Quick Navigation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // First row of navigation (3 buttons)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Transactions',
                    icon: Icons.receipt_long,
                    color: Theme.of(context).primaryColor,
                    onTap: () => context.go('/transactions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Payments',
                    icon: Icons.payment,
                    color: Colors.teal,
                    onTap: () => context.go('/payments'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Expenses',
                    icon: Icons.money_off,
                    color: Colors.orange,
                    onTap: () => context.go('/expenses'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Second row of navigation (2 buttons)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Reports',
                    icon: Icons.analytics,
                    color: Colors.brown,
                    onTap: () => context.go('/reports'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // First row of quick actions (3 buttons)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Add Supplier',
                    icon: Icons.store_mall_directory,
                    color: Colors.orange,
                    onTap: () => context.go('/vendors'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Record Payment',
                    icon: Icons.payment,
                    color: Colors.green,
                    onTap: () => context.go('/payment-received'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Second row of quick actions (3 buttons)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Add Transaction',
                    icon: Icons.receipt_long,
                    color: Colors.purple,
                    onTap: () => context.go('/transactions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'View Reports',
                    icon: Icons.analytics,
                    color: Colors.teal,
                    onTap: () => context.go('/reports'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'Manage Expenses',
                    icon: Icons.account_balance_wallet,
                    color: Colors.red,
                    onTap: () => context.go('/expenses'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tax & Compliance Section
            const Text(
              'Tax & Compliance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    title: 'VAT Filing',
                    icon: Icons.assessment,
                    color: Colors.indigo,
                    onTap: () => context.go('/vat-filing'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalDebtors, double totalCreditors) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Receivables',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BHD ${totalDebtors.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_down, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Payables',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BHD ${totalCreditors.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
