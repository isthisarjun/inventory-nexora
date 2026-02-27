class BankAccount {
  final String bankName;
  final String branch;
  final String accountNumber;
  final String ibanNumber;
  final String registeredMobileNumber;

  const BankAccount({
    required this.bankName,
    required this.branch,
    required this.accountNumber,
    required this.ibanNumber,
    required this.registeredMobileNumber,
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      bankName: map['bankName']?.toString() ?? '',
      branch: map['branch']?.toString() ?? '',
      accountNumber: map['accountNumber']?.toString() ?? '',
      ibanNumber: map['ibanNumber']?.toString() ?? '',
      registeredMobileNumber: map['registeredMobileNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'branch': branch,
      'accountNumber': accountNumber,
      'ibanNumber': ibanNumber,
      'registeredMobileNumber': registeredMobileNumber,
    };
  }

  BankAccount copyWith({
    String? bankName,
    String? branch,
    String? accountNumber,
    String? ibanNumber,
    String? registeredMobileNumber,
  }) {
    return BankAccount(
      bankName: bankName ?? this.bankName,
      branch: branch ?? this.branch,
      accountNumber: accountNumber ?? this.accountNumber,
      ibanNumber: ibanNumber ?? this.ibanNumber,
      registeredMobileNumber:
          registeredMobileNumber ?? this.registeredMobileNumber,
    );
  }

  @override
  String toString() {
    return 'BankAccount(bankName: $bankName, branch: $branch, '
        'accountNumber: $accountNumber, ibanNumber: $ibanNumber, '
        'registeredMobileNumber: $registeredMobileNumber)';
  }
}
