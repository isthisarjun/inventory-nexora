/// Transaction type for a bank transaction.
enum BankTransactionType {
  income,
  expense;

  String get label {
    switch (this) {
      case BankTransactionType.income:
        return 'Income';
      case BankTransactionType.expense:
        return 'Expense';
    }
  }

  static BankTransactionType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'income':
        return BankTransactionType.income;
      case 'expense':
        return BankTransactionType.expense;
      default:
        return BankTransactionType.income;
    }
  }
}

class BankTransaction {
  final String bankName;
  final String accountNumber;
  /// Stored as ISO-8601 date string (yyyy-MM-dd).
  final String transactionDate;
  final BankTransactionType transactionType;
  final double transactionAmount;

  const BankTransaction({
    required this.bankName,
    required this.accountNumber,
    required this.transactionDate,
    required this.transactionType,
    required this.transactionAmount,
  });

  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    return BankTransaction(
      bankName: map['bankName']?.toString() ?? '',
      accountNumber: map['accountNumber']?.toString() ?? '',
      transactionDate: map['transactionDate']?.toString() ?? '',
      transactionType: BankTransactionType.fromString(
        map['transactionType']?.toString() ?? 'income',
      ),
      transactionAmount:
          double.tryParse(map['transactionAmount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'transactionDate': transactionDate,
      'transactionType': transactionType.label,
      'transactionAmount': transactionAmount,
    };
  }

  BankTransaction copyWith({
    String? bankName,
    String? accountNumber,
    String? transactionDate,
    BankTransactionType? transactionType,
    double? transactionAmount,
  }) {
    return BankTransaction(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionType: transactionType ?? this.transactionType,
      transactionAmount: transactionAmount ?? this.transactionAmount,
    );
  }

  @override
  String toString() {
    return 'BankTransaction(bankName: $bankName, accountNumber: $accountNumber, '
        'transactionDate: $transactionDate, transactionType: ${transactionType.label}, '
        'transactionAmount: $transactionAmount)';
  }
}
