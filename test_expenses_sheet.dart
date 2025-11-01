import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('🧾 Creating and testing expenses.xlsx file...\n');
  
  final excelService = ExcelService();
  
  try {
    // Test 1: Create sample expense records
    print('📝 Test 1: Creating sample expense records...');
    
    bool result1 = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now(),
      expenseCategory: 'Office Supplies',
      description: 'Stationery and printing materials',
      amount: 150.50,
      paymentMethod: 'Cash',
      vendorName: 'Office Mart',
      reference: 'INV-001',
    );
    print('✅ Expense 1 saved: $result1');
    
    bool result2 = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now().subtract(Duration(days: 1)),
      expenseCategory: 'Utilities',
      description: 'Monthly electricity bill',
      amount: 85.75,
      paymentMethod: 'Bank Transfer',
      vendorName: 'Electric Company',
      reference: 'BILL-2024-08',
    );
    print('✅ Expense 2 saved: $result2');
    
    bool result3 = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now().subtract(Duration(days: 2)),
      expenseCategory: 'Materials',
      description: 'Fabric and sewing supplies',
      amount: 320.00,
      paymentMethod: 'Credit Card',
      vendorName: 'Fabric Warehouse',
      reference: 'PO-445',
    );
    print('✅ Expense 3 saved: $result3');
    
    // Test 2: Try to save duplicate (should be prevented)
    print('\n📝 Test 2: Testing duplicate prevention...');
    bool duplicateResult = await excelService.saveExpenseToExcel(
      expenseDate: DateTime.now(),
      expenseCategory: 'Office Supplies',
      description: 'Stationery and printing materials', // Same description and amount
      amount: 150.50,
      paymentMethod: 'Cash',
      vendorName: 'Office Mart',
    );
    print('⚠️  Duplicate save attempt result: $duplicateResult (should be false)');
    
    // Test 3: Load all expense records
    print('\n📋 Test 3: Loading all expense records...');
    List<Map<String, dynamic>> expenses = await excelService.loadExpensesFromExcel();
    print('📊 Found ${expenses.length} expense records:');
    
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      print('   ${i + 1}. ${expense['description']}');
      print('      Category: ${expense['category']} | Amount: BHD ${expense['amount']}');
      print('      Vendor: ${expense['vendorName']} | Date: ${expense['expenseDate']}');
      print('      Payment: ${expense['paymentMethod']} | Ref: ${expense['reference']}');
      print('');
    }
    
    // Test 4: Get expense summary by category
    print('📊 Test 4: Getting expense summary by category...');
    Map<String, double> summary = await excelService.getExpenseSummaryByCategory();
    print('Category breakdown:');
    summary.forEach((category, total) {
      print('   - $category: BHD ${total.toStringAsFixed(2)}');
    });
    
    // Test 5: Get total expenses for date range (last 7 days)
    print('\n📅 Test 5: Getting total expenses for last 7 days...');
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: 7));
    double totalExpenses = await excelService.getTotalExpensesForDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    print('Total expenses (last 7 days): BHD ${totalExpenses.toStringAsFixed(2)}');
    
    // Check file location
    final documentsPath = Platform.environment['USERPROFILE'] ?? '';
    final filePath = '$documentsPath\\Documents\\expenses.xlsx';
    final file = File(filePath);
    
    if (await file.exists()) {
      print('\n✅ SUCCESS: expenses.xlsx file created at:');
      print('   📁 $filePath');
      print('   📏 File size: ${await file.length()} bytes');
    } else {
      print('\n❌ ERROR: expenses.xlsx file not found!');
    }
    
    print('\n🎉 All expense tests completed successfully!');
    print('💡 You can now open the Excel file to see the expense records.');
    print('📱 Check the transactions screen with "Business Expenses" filter to see them in the app.');
    
  } catch (e) {
    print('\n❌ Error during testing: $e');
    print('🔍 Stack trace: ${StackTrace.current}');
  }
}
