import 'lib/services/excel_service.dart';

Future<void> main() async {
  print('Testing expense to transaction integration...\n');
  
  final excelService = ExcelService();
  
  try {
    // Test 1: Save a new expense
    print('Test 1: Saving a new expense...');
    final result = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now(),
      expenseCategory: 'Office Supplies',
      description: 'Test Purchase - Office Stationary',
      amount: 25.500,
      paymentMethod: 'Cash',
      vendorName: 'Office Mart',
      reference: 'INV-001',
    );
    
    if (result) {
      print('✅ Expense saved successfully!');
    } else {
      print('❌ Failed to save expense');
    }
    
    // Test 2: Load expenses
    print('\nTest 2: Loading expenses...');
    final expenses = await excelService.loadExpensesFromExcel();
    print('✅ Loaded ${expenses.length} expenses');
    
    // Test 3: Load transactions 
    print('\nTest 3: Loading transactions...');
    final transactions = await excelService.loadTransactionsFromExcel();
    print('✅ Loaded ${transactions.length} transactions');
    
    // Find the transaction that matches our expense
    final expenseTransactions = transactions.where((t) => 
      t['transactionType'] == 'expense' && 
      t['description'].toString().contains('Test Purchase')
    ).toList();
    
    if (expenseTransactions.isNotEmpty) {
      final transaction = expenseTransactions.first;
      print('\n✅ Found expense transaction:');
      print('   Transaction ID: ${transaction['transactionId']}');
      print('   Amount: ${transaction['amount']} BHD (negative = expense)');
      print('   Party: ${transaction['partyName']}');
      print('   Description: ${transaction['description']}');
      print('   Category: ${transaction['category']}');
    } else {
      print('\n❌ No matching expense transaction found');
    }
    
    print('\n🎉 Integration test completed successfully!');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
