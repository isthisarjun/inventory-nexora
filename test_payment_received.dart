import 'lib/services/excel_service.dart';

void main() async {
  print('Testing Payment Received Excel functionality...\n');
  
  final excelService = ExcelService();
  
  try {
    // Test 1: Save a payment record
    print('Test 1: Saving payment record...');
    bool saveResult = await excelService.savePaymentReceivedToExcel(
      paymentDate: DateTime.now(),
      customerName: 'Test Customer',
      saleId: 'SALE001',
      totalSellingPrice: 150.00,
      totalProfit: 50.00,
    );
    print('Save result: $saveResult');
    
    // Test 2: Load payment records
    print('\nTest 2: Loading payment records...');
    List<Map<String, dynamic>> payments = await excelService.loadPaymentReceivedFromExcel();
    print('Found ${payments.length} payment records:');
    for (var payment in payments) {
      print('  - ${payment['paymentDate']}: ${payment['customerName']} - BHD ${payment['totalSellingPrice']} (Profit: BHD ${payment['totalProfit']})');
    }
    
    // Test 3: Save another payment (test duplicate prevention)
    print('\nTest 3: Attempting to save duplicate payment...');
    bool duplicateResult = await excelService.savePaymentReceivedToExcel(
      paymentDate: DateTime.now(),
      customerName: 'Test Customer',
      saleId: 'SALE001', // Same Sale ID
      totalSellingPrice: 150.00,
      totalProfit: 50.00,
    );
    print('Duplicate save result: $duplicateResult');
    
    // Test 4: Load again to confirm no duplicate
    print('\nTest 4: Loading payment records after duplicate attempt...');
    payments = await excelService.loadPaymentReceivedFromExcel();
    print('Found ${payments.length} payment records (should still be 1)');
    
    // Test 5: Save a different payment
    print('\nTest 5: Saving different payment record...');
    bool newSaveResult = await excelService.savePaymentReceivedToExcel(
      paymentDate: DateTime.now().subtract(Duration(days: 1)),
      customerName: 'Another Customer',
      saleId: 'SALE002',
      totalSellingPrice: 200.00,
      totalProfit: 75.00,
    );
    print('New save result: $newSaveResult');
    
    // Test 6: Final load
    print('\nTest 6: Final payment records load...');
    payments = await excelService.loadPaymentReceivedFromExcel();
    print('Found ${payments.length} payment records:');
    for (var payment in payments) {
      print('  - ${payment['paymentDate']}: ${payment['customerName']} - BHD ${payment['totalSellingPrice']} (Profit: BHD ${payment['totalProfit']})');
    }
    
    print('\n✅ All tests completed successfully!');
    
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}
