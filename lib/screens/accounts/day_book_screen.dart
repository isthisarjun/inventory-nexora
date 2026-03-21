import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/excel_service.dart';

class DayBookScreen extends StatefulWidget {
  const DayBookScreen({super.key});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Map<String, dynamic>> _allTransactions = [];

  final ExcelService _excelService = ExcelService();

  // ── Filtered getters (col J = category, col K = flowType) ─────────────────

  /// flowType == 'income' and category does NOT contain 'payment'
  List<Map<String, dynamic>> get _sales {
    final list = _allTransactions.where((t) {
      if (!_sameDay(t['date'] as DateTime?, _selectedDate)) return false;
      final flow = t['flowType']?.toString().toLowerCase().trim() ?? '';
      final cat  = t['category']?.toString().toLowerCase().trim() ?? '';
      return flow == 'income' && !cat.contains('payment');
    }).toList()
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return list;
  }

  /// flowType == 'expense' and category contains 'purchase'
  List<Map<String, dynamic>> get _purchases {
    final list = _allTransactions.where((t) {
      if (!_sameDay(t['date'] as DateTime?, _selectedDate)) return false;
      final flow = t['flowType']?.toString().toLowerCase().trim() ?? '';
      final cat  = t['category']?.toString().toLowerCase().trim() ?? '';
      return flow == 'expense' && cat.contains('purchase');
    }).toList()
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return list;
  }

  /// category contains 'payment'
  List<Map<String, dynamic>> get _creditPayments {
    final list = _allTransactions.where((t) {
      if (!_sameDay(t['date'] as DateTime?, _selectedDate)) return false;
      final cat = t['category']?.toString().toLowerCase().trim() ?? '';
      return cat.contains('payment');
    }).toList()
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return list;
  }

  /// flowType == 'expense', NOT purchase or payment
  List<Map<String, dynamic>> get _expenses {
    final list = _allTransactions.where((t) {
      if (!_sameDay(t['date'] as DateTime?, _selectedDate)) return false;
      final flow = t['flowType']?.toString().toLowerCase().trim() ?? '';
      final cat  = t['category']?.toString().toLowerCase().trim() ?? '';
      return flow == 'expense' &&
          !cat.contains('purchase') &&
          !cat.contains('payment');
    }).toList()
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return list;
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  double get _salesTotal     => _sales.fold(0.0, (s, t) => s + ((t['amount'] as double?)?.abs() ?? 0.0));
  double get _purchasesTotal => _purchases.fold(0.0, (s, t) => s + ((t['amount'] as double?)?.abs() ?? 0.0));
  double get _paymentsTotal  => _creditPayments.fold(0.0, (s, t) => s + ((t['amount'] as double?)?.abs() ?? 0.0));
  double get _expensesTotal  => _expenses.fold(0.0, (s, t) => s + ((t['amount'] as double?)?.abs() ?? 0.0));

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _sameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameDayStr(String? dateStr, DateTime b) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final d = DateTime.parse(dateStr);
      return d.year == b.year && d.month == b.month && d.day == b.day;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  // ── Data loading ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _excelService.loadTransactionsFromExcel();
      if (!mounted) return;
      setState(() => _allTransactions = transactions);
    } catch (_) {
      // silently handle — data just stays empty
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
          tooltip: 'Back to Accounts',
        ),
        title: const Text('Day Book'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 20),

                    const Text(
                      'Day Summary',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(),
                    const SizedBox(height: 24),

                    _buildSection(
                      title: 'Sales',
                      icon: Icons.sell,
                      color: Colors.green,
                      records: _sales,
                      recordBuilder: (r) =>
                          _buildTransactionTile(r, Colors.green),
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      title: 'Purchases',
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      records: _purchases,
                      recordBuilder: (r) =>
                          _buildTransactionTile(r, Colors.orange),
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      title: 'Credit Payments',
                      icon: Icons.payments,
                      color: Colors.blue,
                      records: _creditPayments,
                      recordBuilder: _buildPaymentTile,
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      title: 'Expenses',
                      icon: Icons.money_off,
                      color: Colors.red,
                      records: _expenses,
                      recordBuilder: _buildExpenseTile,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.date_range, size: 16),
              label: const Text('Change Date'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
              label: 'Sales',
              amount: _salesTotal,
              icon: Icons.sell,
              color: Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
              label: 'Purchases',
              amount: _purchasesTotal,
              icon: Icons.shopping_cart,
              color: Colors.orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
              label: 'Payments',
              amount: _paymentsTotal,
              icon: Icons.payments,
              color: Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
              label: 'Expenses',
              amount: _expensesTotal,
              icon: Icons.money_off,
              color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                'BHD ${amount.toStringAsFixed(3)}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> records,
    required Widget Function(Map<String, dynamic>) recordBuilder,
  }) {
    final preview = records.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${records.length}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (preview.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              'No $title records for ${_formatDate(_selectedDate)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...preview.map(recordBuilder),
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> record, Color color) {
    final amount = (record['amount'] as double?)?.abs() ?? 0.0;
    final partyName = record['partyName']?.toString() ?? 'Unknown';
    final description = record['description']?.toString() ?? '';
    final category = record['category']?.toString() ?? '';
    final reference = record['reference']?.toString() ?? '';
    final subtitle = description.isNotEmpty
        ? description
        : (category.isNotEmpty ? category : reference);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            partyName.isNotEmpty ? partyName[0].toUpperCase() : '?',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ),
        title: Text(
          partyName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              )
            : null,
        trailing: Text(
          'BHD ${amount.toStringAsFixed(3)}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> record) {
    final amount     = (record['amount'] as double?)?.abs() ?? 0.0;
    final partyName  = record['partyName']?.toString() ?? 'Unknown';
    final reference  = record['reference']?.toString() ?? '';
    final description = record['description']?.toString() ?? '';
    final subtitle   = reference.isNotEmpty ? 'Ref: $reference' : (description.isNotEmpty ? description : 'Credit Payment');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue[50],
          child: Text(
            partyName.isNotEmpty ? partyName[0].toUpperCase() : '?',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700]),
          ),
        ),
        title: Text(
          partyName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: Text(
          'BHD ${amount.toStringAsFixed(3)}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildExpenseTile(Map<String, dynamic> record) {
    final amount = (record['amount'] as double?) ?? 0.0;
    final description = record['description']?.toString() ?? 'Expense';
    final category = record['category']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.red[50],
          child: const Icon(Icons.receipt_long, size: 16, color: Colors.red),
        ),
        title: Text(
          description,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: category.isNotEmpty
            ? Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              )
            : null,
        trailing: Text(
          'BHD ${amount.toStringAsFixed(3)}',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }
}
