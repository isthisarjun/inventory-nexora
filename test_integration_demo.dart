import 'lib/services/excel_service.dart';

/// Quick test to demonstrate expense-to-transaction integration
Future<void> main() async {
  print('🧪 Testing Expense to Transaction Integration...\n');
  
  final excelService = ExcelService();
  
  try {
    // Step 1: Save a test expense
    print('📝 Step 1: Saving test expense...');
    final result = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now(),
      expenseCategory: 'Office Supplies',
      description: 'Integration Test - Printer Paper',
      amount: 15.750,
      paymentMethod: 'Cash',
      vendorName: 'Office Depot',
      reference: 'TEST-001',
    );
    
    if (result) {
      print('✅ Expense saved successfully!');
    } else {
      print('❌ Failed to save expense');
      return;
    }
    
    // Step 2: Verify transaction was created
    print('\n🔍 Step 2: Checking if transaction was automatically created...');
    final transactions = await excelService.loadTransactionsFromExcel();
    
    // Find transactions that match our test
    final matchingTransactions = transactions.where((t) => 
      t['transactionType'] == 'expense' && 
      t['description'].toString().contains('Integration Test')
    ).toList();
    
    if (matchingTransactions.isNotEmpty) {
      final transaction = matchingTransactions.first;
      print('✅ Found automatic transaction record:');
      print('   Transaction ID: ${transaction['transactionId']}');
      print('   Amount: ${transaction['amount']} BHD (${transaction['amount'].toString().startsWith('-') ? 'NEGATIVE ✅' : 'ERROR ❌'})');
      print('   Party: ${transaction['partyName']}');
      print('   Type: ${transaction['transactionType']}');
      print('   Category: ${transaction['category']}');
      print('   Flow Type: ${transaction['flowType']}');
      
      // Verify it's properly marked as expense (negative amount)
      final amount = double.tryParse(transaction['amount'].toString()) ?? 0;
      if (amount < 0) {
        print('\n🎉 SUCCESS: Integration working correctly!');
        print('   ✅ Expense recorded in expenses.xlsx');
        print('   ✅ Transaction automatically created in transaction_details.xlsx');
        print('   ✅ Amount correctly shows as negative (money going out)');
      } else {
        print('\n❌ ERROR: Amount should be negative for expenses');
      }
    } else {
      print('❌ No matching transaction found - integration may have failed');
    }
    
    // Step 3: Summary
    print('\n📊 Summary:');
    print('   Total Expenses: ${await excelService.loadExpensesFromExcel().then((e) => e.length)}');
    print('   Total Transactions: ${transactions.length}');
    print('   Expense Transactions: ${transactions.where((t) => t['transactionType'] == 'expense').length}');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
