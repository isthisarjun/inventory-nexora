class Account {
  final String id;
  final String name;
  final String type; // 'customer' or 'supplier'
  final double balance; // positive for debit (owed to us), negative for credit (we owe)
  final String email;
  final String phone;
  final String address;
  final DateTime lastTransactionDate;
  final List<Transaction> transactions;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.email,
    required this.phone,
    required this.address,
    required this.lastTransactionDate,
    this.transactions = const [],
  });

  bool get isCustomer => type == 'customer';
  bool get isSupplier => type == 'supplier';
  bool get hasOutstandingBalance => balance != 0;
  double get debitBalance => balance > 0 ? balance : 0;
  double get creditBalance => balance < 0 ? balance.abs() : 0;

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? email,
    String? phone,
    String? address,
    DateTime? lastTransactionDate,
    List<Transaction>? transactions,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'email': email,
      'phone': phone,
      'address': address,
      'lastTransactionDate': lastTransactionDate.toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'customer',
      balance: (json['balance'] ?? 0).toDouble(),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      lastTransactionDate: DateTime.tryParse(json['lastTransactionDate'] ?? '') ?? DateTime.now(),
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((t) => Transaction.fromJson(t))
          .toList() ?? [],
    );
  }
}

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount; // positive for debit, negative for credit
  final String type; // 'invoice', 'payment', 'credit_note', etc.
  final String reference;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.reference = '',
  });

  bool get isDebit => amount > 0;
  bool get isCredit => amount < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'type': type,
      'reference': reference,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      reference: json['reference'] ?? '',
    );
  }
}
