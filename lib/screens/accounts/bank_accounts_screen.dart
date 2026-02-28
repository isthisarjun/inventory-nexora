import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/excel_service.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final ExcelService _excelService = ExcelService();
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _excelService.loadBankAccountsFromExcel();
      if (!mounted) return;
      setState(() {
        _accounts = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error loading bank accounts: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAccountDialog({Map<String, dynamic>? existing}) async {
    final isEditing = existing != null;
    final bankNameCtrl = TextEditingController(text: existing?['bankName'] ?? '');
    final branchCtrl = TextEditingController(text: existing?['branch'] ?? '');
    final accountNumberCtrl = TextEditingController(text: existing?['accountNumber'] ?? '');
    final ibanCtrl = TextEditingController(text: existing?['ibanNumber'] ?? '');
    final mobileCtrl = TextEditingController(text: existing?['registeredMobileNumber'] ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        actionsPadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[600],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Bank Account' : 'Add Bank Account',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Bank Name | Branch
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildField(
                            bankNameCtrl, 'Bank Name', Icons.account_balance),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                            branchCtrl, 'Branch', Icons.location_on),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 2: Account Number | IBAN Number
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildField(
                            accountNumberCtrl, 'Account Number',
                            Icons.credit_card,
                            required: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                            ibanCtrl, 'IBAN Number', Icons.numbers),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 3: Mobile (full width)
                  _buildField(
                      mobileCtrl, 'Registered Mobile Number', Icons.phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600]),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text(isEditing ? 'Update' : 'Add Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: const [],
      ),
    );

    if (confirmed != true) return;

    final accountData = {
      'bankName': bankNameCtrl.text.trim(),
      'branch': branchCtrl.text.trim(),
      'accountNumber': accountNumberCtrl.text.trim(),
      'ibanNumber': ibanCtrl.text.trim(),
      'registeredMobileNumber': mobileCtrl.text.trim(),
    };

    final bool success;
    if (isEditing) {
      success = await _excelService.updateBankAccountInExcel(
          accountData, existing!['accountNumber'] ?? '');
    } else {
      success = await _excelService.saveBankAccountToExcel(accountData);
    }

    if (!mounted) return;
    if (success) {
      _showSnack(isEditing ? 'Account updated' : 'Account added');
      await _loadAccounts();
    } else {
      _showSnack('Failed to ${isEditing ? 'update' : 'add'} account', isError: true);
    }
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[600],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Delete Bank Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: Text(
            'Delete "${account['bankName']} \u2013 ${account['accountNumber']}"?\n\nLinked transactions will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success =
        await _excelService.deleteBankAccountFromExcel(account['accountNumber'] ?? '');
    if (!mounted) return;
    if (success) {
      _showSnack('Account deleted');
      await _loadAccounts();
    } else {
      _showSnack('Failed to delete account', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
          tooltip: 'Back',
        ),
        title: const Text('Bank Accounts'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadAccounts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountDialog(),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bank accounts yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first bank account.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildList() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final a = _accounts[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.account_balance,
                            color: Colors.green[700], size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (a['bankName'] as String?)?.isNotEmpty == true
                                  ? a['bankName']
                                  : 'Unknown Bank',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if ((a['branch'] as String?)?.isNotEmpty == true)
                              Text(a['branch'],
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _showAccountDialog(existing: a);
                          if (v == 'delete') _confirmDelete(a);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _row(Icons.numbers, 'Account No.', a['accountNumber'] ?? ''),
                  if ((a['ibanNumber'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _row(Icons.credit_card, 'IBAN', a['ibanNumber']),
                  ],
                  if ((a['registeredMobileNumber'] as String?)?.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 6),
                    _row(Icons.phone, 'Mobile', a['registeredMobileNumber']),
                  ],
                ],
              ),
            ),
          );
        },
      );

  Widget _row(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}
