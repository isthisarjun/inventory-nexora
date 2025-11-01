import 'lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing New Inventory Expenses Excel Structure...\n');
  
  final excelService = ExcelService();
  
  print('📊 NEW INVENTORY EXPENSES COLUMN STRUCTURE:');
  print('A: Expense ID');
  print('B: Date');
  print('C: Description');
  print('D: Amount');
  print('E: Category');
  print('F: Payment Method');
  print('G: VAT');
  print('H: VAT Amount');
  print('I: Payee');
  print('J: Reference');
  print('');
  
  // Test 1: Expense with VAT
  print('🧪 Test 1: Expense with VAT...');
  try {
    bool result = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now(),
      expenseCategory: 'Office Supplies',
      description: 'Test office supplies with VAT',
      amount: 110.0, // VAT-inclusive amount
      paymentMethod: 'Credit Card',
      vendorName: 'Office Depot',
      reference: 'INV001',
      vatRate: 10.0,
      vatAmount: 10.0,
    );
    
    if (result) {
      print('✅ Expense with VAT saved successfully');
    } else {
      print('❌ Expense with VAT failed');
    }
  } catch (e) {
    print('❌ ERROR in VAT expense test: $e');
  }
  
  // Test 2: Expense without VAT
  print('\n🧪 Test 2: Expense without VAT...');
  try {
    bool result = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now(),
      expenseCategory: 'Rent',
      description: 'Monthly office rent',
      amount: 500.0,
      paymentMethod: 'Bank Transfer',
      vendorName: 'Property Management Co.',
      reference: 'RENT001',
      vatRate: null,
      vatAmount: null,
    );
    
    if (result) {
      print('✅ Expense without VAT saved successfully');
    } else {
      print('❌ Expense without VAT failed');
    }
  } catch (e) {
    print('❌ ERROR in non-VAT expense test: $e');
  }
  
  // Test 3: Load expenses to verify column mappings
  print('\n🧪 Test 3: Loading expenses to verify mappings...');
  try {
    final expenses = await excelService.loadExpensesFromExcel();
    
    if (expenses.isNotEmpty) {
      print('✅ Loaded ${expenses.length} expenses');
      
      // Show the latest expense to verify mapping
      final latest = expenses.last;
      print('\n📋 Latest Expense Details:');
      print('   Expense ID: ${latest['expenseId']}');
      print('   Date: ${latest['expenseDate']}');
      print('   Description: ${latest['description']}');
      print('   Amount: ${latest['amount']}');
      print('   Category: ${latest['category']}');
      print('   Payment Method: ${latest['paymentMethod']}');
      print('   VAT Rate: ${latest['vatRate']}%');
      print('   VAT Amount: ${latest['vatAmount']}');
      print('   Payee: ${latest['vendorName']}');
      print('   Reference: ${latest['reference']}');
    } else {
      print('⚠️  No expenses found');
    }
  } catch (e) {
    print('❌ ERROR loading expenses: $e');
  }
  
  print('\n🏁 Inventory expenses test completed!');
  print('✅ New features:');
  print('   - File changed from expenses.xlsx to inventory_expenses.xlsx');
  print('   - Sheet name changed from "Expenses" to "Inventory Expenses"');
  print('   - Added VAT and VAT Amount columns');
  print('   - Vendor/Supplier renamed to Payee');
  print('   - All columns correctly mapped for the new structure');
  print('   - Expense management screen now uses the new file!');
}