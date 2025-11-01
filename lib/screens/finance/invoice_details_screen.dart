import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const InvoiceDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final orderDate = DateTime.tryParse(order['orderDate']?.toString() ?? '') ?? DateTime.now();
    final dueDate = DateTime.tryParse(order['dueDate']?.toString() ?? '') ?? DateTime.now();
    final totalCost = double.tryParse(order['totalCost']?.toString() ?? '0') ?? 0.0;
    final advanceAmount = double.tryParse(order['advanceAmount']?.toString() ?? '0') ?? 0.0;
    final materialsCost = double.tryParse(order['materialsCost']?.toString() ?? '0') ?? 0.0;
    final labourCost = double.tryParse(order['labourCost']?.toString() ?? '0') ?? 0.0;
    final balanceAmount = totalCost - advanceAmount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/invoices'),
          tooltip: 'Back to Invoices',
        ),
        title: Text('Invoice #${order['id'] ?? 'N/A'}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'Print Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context),
            tooltip: 'Share Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with company info
                  _buildInvoiceHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Invoice details and customer info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInvoiceInfo(orderDate, dueDate),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: _buildCustomerInfo(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Items table
                  _buildItemsTable(materialsCost, labourCost),
                  
                  const SizedBox(height: 24),
                  
                  // Totals section
                  _buildTotalsSection(totalCost, advanceAmount, balanceAmount),
                  
                  const SizedBox(height: 32),
                  
                  // Payment info and notes
                  _buildPaymentInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // Footer
                  _buildInvoiceFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Company logo placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cut,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nexora Tailoring',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Professional Tailoring Services',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'INVOICE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey[300], thickness: 2),
      ],
    );
  }

  Widget _buildInvoiceInfo(DateTime orderDate, DateTime dueDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invoice Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Invoice Number:', '#${order['id'] ?? 'N/A'}'),
        _buildInfoRow('Order Date:', _formatDate(orderDate)),
        _buildInfoRow('Due Date:', _formatDate(dueDate)),
        _buildInfoRow('Status:', _getStatusDisplayText(order['status']?.toString() ?? '')),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bill To',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          order['customerName'] ?? 'Unknown Customer',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (order['customerContact'] != null && order['customerContact'].toString().isNotEmpty)
          Text(
            'Phone: ${order['customerContact']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        if (order['customerAddress'] != null && order['customerAddress'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              order['customerAddress'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemsTable(double materialsCost, double labourCost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items & Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Amount (BHD)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              
              // Items rows
              _buildTableRow(
                order['outfitType'] ?? 'Tailoring Services',
                _extractQuantityFromItems(order['outfitType']?.toString() ?? ''),
                labourCost,
              ),
              
              if (materialsCost > 0)
                _buildTableRow(
                  'Materials & Fabrics',
                  '1',
                  materialsCost,
                ),
              
              if (order['specialInstructions'] != null && order['specialInstructions'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Instructions:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order['specialInstructions'],
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String description, String quantity, double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              quantity,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount.toStringAsFixed(2),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(double totalCost, double advanceAmount, double balanceAmount) {
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildTotalRow('Subtotal:', totalCost.toStringAsFixed(2), false),
              if (advanceAmount > 0) ...[
                const SizedBox(height: 8),
                _buildTotalRow('Advance Paid:', '-${advanceAmount.toStringAsFixed(2)}', false),
                Divider(color: Colors.grey[300]),
              ],
              _buildTotalRow('Total Amount:', totalCost.toStringAsFixed(2), true),
              if (balanceAmount > 0) ...[
                const SizedBox(height: 8),
                _buildTotalRow('Balance Due:', balanceAmount.toStringAsFixed(2), true, color: Colors.orange[700]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String amount, bool isBold, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          'BHD $amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: order['paymentStatus'] == 'paid' ? Colors.green[50] : Colors.orange[50],
        border: Border.all(
          color: order['paymentStatus'] == 'paid' ? Colors.green[200]! : Colors.orange[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            order['paymentStatus'] == 'paid' ? Icons.check_circle : Icons.schedule,
            color: order['paymentStatus'] == 'paid' ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['paymentStatus'] == 'paid' ? 'Payment Completed' : 'Payment Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: order['paymentStatus'] == 'paid' ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order['paymentStatus'] == 'paid' 
                    ? 'Thank you for your payment!'
                    : 'Please complete payment to process your order.',
                  style: TextStyle(
                    fontSize: 12,
                    color: order['paymentStatus'] == 'paid' ? Colors.green[600] : Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceFooter() {
    return Column(
      children: [
        Divider(color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text(
          'Thank you for choosing Nexora Tailoring!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'For any questions about this invoice, please contact us.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Generated on ${_formatDate(DateTime.now())}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  String _extractQuantityFromItems(String items) {
    // Extract total quantity from items like "Shirt (2), Pants (3)"
    int totalQuantity = 0;
    final matches = RegExp(r'\((\d+)\)').allMatches(items);
    for (final match in matches) {
      totalQuantity += int.parse(match.group(1)!);
    }
    return totalQuantity > 0 ? totalQuantity.toString() : '1';
  }

  void _printInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
