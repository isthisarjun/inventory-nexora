import 'lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing Updated Transaction Column Mappings...\n');
  
  final excelService = ExcelService();
  
  print('📊 NEW COLUMN STRUCTURE:');
  print('A: Transaction ID');
  print('B: Date & Time');
  print('C: Transaction Type');
  print('D: Party Name');
  print('E: Amount (BHD)');
  print('F: VAT');
  print('G: VAT Amount');
  print('H: Description');
  print('I: Reference');
  print('J: Category');
  print('K: Flow Type');
  print('');
  
  // Test 1: Sale with VAT
  print('🧪 Test 1: Sale with VAT...');
  try {
    bool result = await excelService.saveTransactionToExcel(
      transactionType: 'sale',
      partyName: 'Test Customer',
      amount: 110.0, // VAT-inclusive amount
      description: 'Test sale with VAT',
      reference: 'SALE001',
      category: 'Sales Revenue',
      vatRate: 10.0,
      vatAmount: 10.0,
    );
    
    if (result) {
      print('✅ Sale transaction saved successfully');
    } else {
      print('❌ Sale transaction failed');
    }
  } catch (e) {
    print('❌ ERROR in sale test: $e');
  }
  
  // Test 2: Expense without VAT
  print('\n🧪 Test 2: Expense without VAT...');
  try {
    bool result = await excelService.saveTransactionToExcel(
      transactionType: 'expense',
      partyName: 'Test Vendor',
      amount: -50.0, // Negative for expense
      description: 'Test expense without VAT',
      reference: 'EXP001',
      category: 'Office Supplies',
      vatRate: null,
      vatAmount: null,
    );
    
    if (result) {
      print('✅ Expense transaction saved successfully');
    } else {
      print('❌ Expense transaction failed');
    }
  } catch (e) {
    print('❌ ERROR in expense test: $e');
  }
  
  // Test 3: Load transactions to verify column mappings
  print('\n🧪 Test 3: Loading transactions to verify mappings...');
  try {
    final transactions = await excelService.loadTransactionsFromExcel();
    
    if (transactions.isNotEmpty) {
      print('✅ Loaded ${transactions.length} transactions');
      
      // Show the latest transaction to verify mapping
      final latest = transactions.last;
      print('\n📋 Latest Transaction Details:');
      print('   Transaction ID: ${latest['transactionId']}');
      print('   Date: ${latest['date']}');
      print('   Type: ${latest['transactionType']}');
      print('   Party: ${latest['partyName']}');
      print('   Amount: ${latest['amount']} BHD');
      print('   VAT Rate: ${latest['vatRate']}%');
      print('   VAT Amount: ${latest['vatAmount']} BHD');
      print('   Description: ${latest['description']}');
      print('   Reference: ${latest['reference']}');
      print('   Category: ${latest['category']}');
      print('   Flow Type: ${latest['flowType']}');
    } else {
      print('⚠️  No transactions found');
    }
  } catch (e) {
    print('❌ ERROR loading transactions: $e');
  }
  
  print('\n🏁 Column mapping test completed!');
  print('✅ All transaction columns should now map correctly:');
  print('   - Description moved from F to H');
  print('   - Reference moved from G to I');
  print('   - Category moved from H to J');
  print('   - Flow Type moved from I to K');
  print('   - New VAT columns added at F and G');
}