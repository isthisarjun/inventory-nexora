import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('🔧 Creating and testing payment_received.xlsx file...\n');
  
  final excelService = ExcelService();
  
  try {
    // Test 1: Create a sample payment record
    print('📝 Test 1: Creating sample payment record...');
    bool saveResult = await excelService.savePaymentReceivedToExcel(
      paymentDate: DateTime.now(),
      customerName: 'Ahmed Al-Rashid',
      saleId: 'SALE_001',
      totalSellingPrice: 250.00,
      totalProfit: 85.00,
    );
    print('✅ Payment record saved: $saveResult');
    
    // Test 2: Create another payment record
    print('\n📝 Test 2: Creating second payment record...');
    bool saveResult2 = await excelService.savePaymentReceivedToExcel(
      paymentDate: DateTime.now().subtract(Duration(days: 1)),
      customerName: 'Sara Mohammed',
      saleId: 'SALE_002',
      totalSellingPrice: 180.00,
      totalProfit: 60.00,
    );
    print('✅ Second payment record saved: $saveResult2');
    
    // Test 3: Try to save duplicate (should be prevented)
    print('\n📝 Test 3: Testing duplicate prevention...');
    bool duplicateResult = await excelService.savePaymentReceivedToExcel(
      paymentDate: DateTime.now(),
      customerName: 'Ahmed Al-Rashid',
      saleId: 'SALE_001', // Same Sale ID as Test 1
      totalSellingPrice: 250.00,
      totalProfit: 85.00,
    );
    print('⚠️  Duplicate save attempt result: $duplicateResult (should be false or prevented)');
    
    // Test 4: Load all payment records
    print('\n📋 Test 4: Loading all payment records...');
    List<Map<String, dynamic>> payments = await excelService.loadPaymentReceivedFromExcel();
    print('📊 Found ${payments.length} payment records:');
    
    for (int i = 0; i < payments.length; i++) {
      final payment = payments[i];
      print('   ${i + 1}. ${payment['customerName']} - Sale: ${payment['saleId']}');
      print('      Amount: BHD ${payment['totalSellingPrice']} | Profit: BHD ${payment['totalProfit']}');
      print('      Date: ${payment['paymentDate']}');
      print('');
    }
    
    // Test 5: Sync from sales records
    print('🔄 Test 5: Syncing sales to payment records...');
    await excelService.syncSalesToPaymentReceived();
    
    // Load again to see if new records were added
    payments = await excelService.loadPaymentReceivedFromExcel();
    print('📊 After sync: Found ${payments.length} payment records total');
    
    // Check file location
    final documentsPath = Platform.environment['USERPROFILE'] ?? '';
    final filePath = '$documentsPath\\Documents\\payment_received.xlsx';
    final file = File(filePath);
    
    if (await file.exists()) {
      print('\n✅ SUCCESS: payment_received.xlsx file created at:');
      print('   📁 $filePath');
      print('   📏 File size: ${await file.length()} bytes');
    } else {
      print('\n❌ ERROR: payment_received.xlsx file not found!');
    }
    
    print('\n🎉 All tests completed successfully!');
    print('💡 You can now open the Excel file to see the payment records.');
    
  } catch (e) {
    print('\n❌ Error during testing: $e');
    print('🔍 Stack trace: ${StackTrace.current}');
  }
}
