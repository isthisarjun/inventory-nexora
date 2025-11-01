import 'package:flutter/material.dart';
import 'lib/services/excel_service.dart';

/// Quick test to verify the purchase history fix
Future<void> testPurchaseHistoryFix() async {
  print('🧪 Testing Purchase History Fix');
  print('=' * 50);
  
  final excelService = ExcelService();
  
  // First, debug the file structure
  print('📋 Step 1: Debugging purchase file structure...');
  await excelService.debugPurchaseFile();
  
  print('\n📊 Step 2: Loading grouped purchase history...');
  final purchases = await excelService.getGroupedPurchaseHistory();
  
  print('\n📈 Results Summary:');
  print('   📦 Total purchases found: ${purchases.length}');
  
  if (purchases.isNotEmpty) {
    print('   ✅ SUCCESS: Purchase data is loading correctly!');
    print('\n📋 Sample purchases:');
    for (int i = 0; i < (purchases.length > 3 ? 3 : purchases.length); i++) {
      final purchase = purchases[i];
      print('   ${i + 1}. ${purchase['purchaseId']} - ${purchase['vendorName']} - ${purchase['itemCount']} items - BHD ${(purchase['totalAmount'] as double).toStringAsFixed(2)}');
    }
  } else {
    print('   ❌ WARNING: No purchase data found');
    print('   This could mean:');
    print('     - The Excel file is empty');
    print('     - The file structure does not match expectations');
    print('     - There are no purchases saved yet');
  }
  
  print('\n🎯 Test Complete!');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await testPurchaseHistoryFix();
}
