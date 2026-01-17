/// Model for VAT Filing data structure containing purchase ledger, sales ledger, and summary

class VatFilingData {
  final String taxPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final List<PurchaseLedgerEntry> purchaseLedger;
  final List<SalesLedgerEntry> salesLedger;
  VatSummary vatSummary;
  final String filePath;

  VatFilingData({
    required this.taxPeriod,
    required this.startDate,
    required this.endDate,
    required this.purchaseLedger,
    required this.salesLedger,
    required this.vatSummary,
    required this.filePath,
  });

  /// Create a copy with modifications
  VatFilingData copyWith({
    String? taxPeriod,
    DateTime? startDate,
    DateTime? endDate,
    List<PurchaseLedgerEntry>? purchaseLedger,
    List<SalesLedgerEntry>? salesLedger,
    VatSummary? vatSummary,
    String? filePath,
  }) {
    return VatFilingData(
      taxPeriod: taxPeriod ?? this.taxPeriod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      purchaseLedger: purchaseLedger ?? this.purchaseLedger,
      salesLedger: salesLedger ?? this.salesLedger,
      vatSummary: vatSummary ?? this.vatSummary,
      filePath: filePath ?? this.filePath,
    );
  }

  /// Recalculate VAT summary based on current ledger data
  void recalculateSummary() {
    double totalOutputVat = 0.0;
    double totalInputVat = 0.0;

    // Sum output VAT from sales ledger
    for (final entry in salesLedger) {
      totalOutputVat += entry.vatAmount;
    }

    // Sum input VAT from purchase ledger (only claimable)
    for (final entry in purchaseLedger) {
      if (entry.isClaimable) {
        totalInputVat += entry.vatAmount;
      }
    }

    vatSummary.totalOutputVat = totalOutputVat;
    vatSummary.totalInputVat = totalInputVat;
    vatSummary.netVatPayable = totalOutputVat - totalInputVat;
  }
}

/// Purchase Ledger Entry (Input VAT from expenses/purchases)
class PurchaseLedgerEntry {
  final String date; // dd/MM/yyyy format
  final String invoiceId;
  final String vendorName;
  double netAmount;
  final double vatRate;
  double vatAmount;
  double totalAmount;
  bool isClaimable;
  String? category;

  PurchaseLedgerEntry({
    required this.date,
    required this.invoiceId,
    required this.vendorName,
    required this.netAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    required this.isClaimable,
    this.category,
  });

  /// Create a copy with modifications
  PurchaseLedgerEntry copyWith({
    String? date,
    String? invoiceId,
    String? vendorName,
    double? netAmount,
    double? vatRate,
    double? vatAmount,
    double? totalAmount,
    bool? isClaimable,
    String? category,
  }) {
    return PurchaseLedgerEntry(
      date: date ?? this.date,
      invoiceId: invoiceId ?? this.invoiceId,
      vendorName: vendorName ?? this.vendorName,
      netAmount: netAmount ?? this.netAmount,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      isClaimable: isClaimable ?? this.isClaimable,
      category: category ?? this.category,
    );
  }

  /// Recalculate total amount based on net amount and VAT
  void recalculateTotal() {
    totalAmount = netAmount + vatAmount;
  }
}

/// Sales Ledger Entry (Output VAT from sales/income)
class SalesLedgerEntry {
  final String date; // dd/MM/yyyy format
  final String receiptId;
  final String customerName;
  double netSales;
  final double vatRate;
  double vatAmount;
  double totalCollected;

  SalesLedgerEntry({
    required this.date,
    required this.receiptId,
    required this.customerName,
    required this.netSales,
    required this.vatRate,
    required this.vatAmount,
    required this.totalCollected,
  });

  /// Create a copy with modifications
  SalesLedgerEntry copyWith({
    String? date,
    String? receiptId,
    String? customerName,
    double? netSales,
    double? vatRate,
    double? vatAmount,
    double? totalCollected,
  }) {
    return SalesLedgerEntry(
      date: date ?? this.date,
      receiptId: receiptId ?? this.receiptId,
      customerName: customerName ?? this.customerName,
      netSales: netSales ?? this.netSales,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalCollected: totalCollected ?? this.totalCollected,
    );
  }

  /// Recalculate total collected based on net sales and VAT
  void recalculateTotal() {
    totalCollected = netSales + vatAmount;
  }
}

/// VAT Summary totals
class VatSummary {
  String taxPeriod;
  double totalOutputVat;
  double totalInputVat;
  double netVatPayable;

  VatSummary({
    required this.taxPeriod,
    required this.totalOutputVat,
    required this.totalInputVat,
    required this.netVatPayable,
  });

  /// Determine if net VAT is payable (positive) or refundable (negative)
  String get status {
    if (netVatPayable > 0) {
      return 'Payable';
    } else if (netVatPayable < 0) {
      return 'Refundable';
    } else {
      return 'Nil';
    }
  }

  /// Get the absolute amount due
  double get amountDue => netVatPayable.abs();
}
