import 'package:flutter/material.dart';
import 'package:tailor_v3/models/vat_filing_data.dart';

class LedgerScreen extends StatelessWidget {
  final List<PurchaseLedgerEntry> purchaseEntries;
  final List<SalesLedgerEntry> salesEntries;
  final void Function(int index, PurchaseLedgerEntry updatedEntry) onEditPurchase;
  final void Function(int index, SalesLedgerEntry updatedEntry) onEditSales;

  const LedgerScreen({
    super.key,
    required this.purchaseEntries,
    required this.salesEntries,
    required this.onEditPurchase,
    required this.onEditSales,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purchase Ledger Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Purchase Ledger (Input VAT)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${purchaseEntries.length} entries',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green[800]),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Invoice ID')),
                DataColumn(label: Text('Vendor')),
                DataColumn(label: Text('Net Amount')),
                DataColumn(label: Text('VAT Rate %')),
                DataColumn(label: Text('VAT Amount')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Claimable')),
                DataColumn(label: Text('Actions')),
              ],
              rows: purchaseEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return DataRow(cells: [
                  DataCell(Text(e.date)),
                  DataCell(Text(e.invoiceId)),
                  DataCell(Text(e.vendorName)),
                  DataCell(Text(e.netAmount.toStringAsFixed(3))),
                  DataCell(Text('${e.vatRate.toStringAsFixed(1)}%')),
                  DataCell(Text(e.vatAmount.toStringAsFixed(3))),
                  DataCell(Text(e.totalAmount.toStringAsFixed(3))),
                  DataCell(Chip(
                    label: Text(e.isClaimable ? 'Yes' : 'No'),
                    backgroundColor: e.isClaimable ? Colors.green[100] : Colors.red[100],
                    labelStyle: TextStyle(color: e.isClaimable ? Colors.green[800] : Colors.red[800]),
                  )),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _EditPurchaseLedgerDialog(
                        entry: e,
                        onSave: (updatedEntry) {
                          onEditPurchase(idx, updatedEntry);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    tooltip: 'Edit',
                  )),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Sales Ledger Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Sales Ledger (Output VAT)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${salesEntries.length} entries',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Receipt ID')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Net Sales')),
                DataColumn(label: Text('VAT Rate %')),
                DataColumn(label: Text('VAT Amount')),
                DataColumn(label: Text('Total Collected')),
                DataColumn(label: Text('Actions')),
              ],
              rows: salesEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return DataRow(cells: [
                  DataCell(Text(e.date)),
                  DataCell(Text(e.receiptId)),
                  DataCell(Text(e.customerName)),
                  DataCell(Text(e.netSales.toStringAsFixed(3))),
                  DataCell(Text('${e.vatRate.toStringAsFixed(1)}%')),
                  DataCell(Text(e.vatAmount.toStringAsFixed(3))),
                  DataCell(Text(e.totalCollected.toStringAsFixed(3))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _EditSalesLedgerDialog(
                        entry: e,
                        onSave: (updatedEntry) {
                          onEditSales(idx, updatedEntry);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    tooltip: 'Edit',
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to edit Purchase Ledger entries
class _EditPurchaseLedgerDialog extends StatefulWidget {
  final PurchaseLedgerEntry entry;
  final Function(PurchaseLedgerEntry) onSave;

  const _EditPurchaseLedgerDialog({
    required this.entry,
    required this.onSave,
  });

  @override
  State<_EditPurchaseLedgerDialog> createState() => _EditPurchaseLedgerDialogState();
}

class _EditPurchaseLedgerDialogState extends State<_EditPurchaseLedgerDialog> {
  late TextEditingController _netAmountController;
  late TextEditingController _vatAmountController;
  late bool _isClaimable;

  @override
  void initState() {
    super.initState();
    _netAmountController = TextEditingController(text: widget.entry.netAmount.toString());
    _vatAmountController = TextEditingController(text: widget.entry.vatAmount.toString());
    _isClaimable = widget.entry.isClaimable;
  }

  @override
  void dispose() {
    _netAmountController.dispose();
    _vatAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Purchase Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${widget.entry.invoiceId}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Vendor: ${widget.entry.vendorName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _netAmountController,
              decoration: const InputDecoration(labelText: 'Net Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vatAmountController,
              decoration: const InputDecoration(labelText: 'VAT Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Is Claimable?'),
              value: _isClaimable,
              onChanged: (value) => setState(() => _isClaimable = value ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
      ],
    );
  }

  void _saveChanges() {
    final netAmount = double.tryParse(_netAmountController.text) ?? 0.0;
    final vatAmount = double.tryParse(_vatAmountController.text) ?? 0.0;

    final updatedEntry = widget.entry.copyWith(
      netAmount: netAmount,
      vatAmount: vatAmount,
      isClaimable: _isClaimable,
      totalAmount: netAmount + vatAmount,
    );

    widget.onSave(updatedEntry);
  }
}

class _EditSalesLedgerDialog extends StatefulWidget {
  final SalesLedgerEntry entry;
  final Function(SalesLedgerEntry) onSave;

  const _EditSalesLedgerDialog({
    required this.entry,
    required this.onSave,
  });

  @override
  State<_EditSalesLedgerDialog> createState() => _EditSalesLedgerDialogState();
}

class _EditSalesLedgerDialogState extends State<_EditSalesLedgerDialog> {
  late TextEditingController _netSalesController;
  late TextEditingController _vatAmountController;

  @override
  void initState() {
    super.initState();
    _netSalesController = TextEditingController(text: widget.entry.netSales.toString());
    _vatAmountController = TextEditingController(text: widget.entry.vatAmount.toString());
  }

  @override
  void dispose() {
    _netSalesController.dispose();
    _vatAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Sales Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt: ${widget.entry.receiptId}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Customer: ${widget.entry.customerName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _netSalesController,
              decoration: const InputDecoration(labelText: 'Net Sales', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vatAmountController,
              decoration: const InputDecoration(labelText: 'VAT Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
      ],
    );
  }

  void _saveChanges() {
    final netSales = double.tryParse(_netSalesController.text) ?? 0.0;
    final vatAmount = double.tryParse(_vatAmountController.text) ?? 0.0;

    final updatedEntry = widget.entry.copyWith(
      netSales: netSales,
      vatAmount: vatAmount,
      totalCollected: netSales + vatAmount,
    );

    widget.onSave(updatedEntry);
  }
}