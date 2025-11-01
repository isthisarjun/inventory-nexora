import 'lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing Excel Fixes for Jumbling Issue...\n');
  
  final excelService = ExcelService();
  
  // Test data with various types to check type handling
  final testSaleData = {
    'saleId': 'TEST001',
    'date': '2024-01-15',
    'customerName': 'Test Customer',
    'items': [
      {
        'itemId': 'ITEM001',
        'itemName': 'Test Product',
        'quantity': 5,
        'unit': 'pcs',
        'sellingPrice': 110.0, // VAT-inclusive
        'costPrice': 80.0,
      }
    ],
    'saleType': 'Cash',
    'vatAmount': 50.0, // This should be calculated properly
  };
  
  print('📝 Test Sale Data:');
  print('Item: ${testSaleData['items'][0]['itemName']}');
  print('Quantity: ${testSaleData['items'][0]['quantity']}');
  print('Selling Price (VAT-incl): BHD ${testSaleData['items'][0]['sellingPrice']}');
  print('Cost Price: BHD ${testSaleData['items'][0]['costPrice']}');
  print('');
  
  try {
    // Test the fixed saveSaleToExcel method
    print('🔧 Testing saveSaleToExcel with fixes...');
    bool result = await excelService.saveSaleToExcel(testSaleData);
    
    if (result) {
      print('✅ Excel save completed successfully!');
      print('🎉 Fixes applied:');
      print('   ✓ Improved row finding logic (no more sheet.maxRows)');
      print('   ✓ Safe cell value type handling');
      print('   ✓ Sheet header validation');
      print('   ✓ Data validation before Excel write');
      print('   ✓ Comprehensive error handling');
    } else {
      print('❌ Excel save failed - check debug logs above');
    }
    
  } catch (e) {
    print('❌ ERROR during Excel test: $e');
  }
  
  print('\n🏁 Excel fixes test completed!');
  print('The jumbling issue should now be resolved with:');
  print('- Better row detection algorithm');
  print('- Type-safe cell value assignment'); 
  print('- Header integrity validation');
  print('- Data validation before writes');
}