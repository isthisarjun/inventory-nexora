import 'lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing Vendor Credit Update Functionality');
  
  // Test vendor credit update
  final excelService = ExcelService();
  
  print('\n1. Testing vendor credit addition...');
  final result1 = await excelService.updateVendorCredit('Sky International', 100.0, 'add');
  print('Result: $result1');
  
  print('\n2. Testing vendor credit subtraction...');
  final result2 = await excelService.updateVendorCredit('Sky International', 50.0, 'subtract');
  print('Result: $result2');
  
  print('\n3. Testing vendor credit payment...');
  final result3 = await excelService.processVendorCreditPayment('Sky International', 25.0);
  print('Result: $result3');
  
  print('\n✅ Vendor credit tests completed');
}
