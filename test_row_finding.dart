import 'lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing Excel Row Finding Logic...\n');
  
  final excelService = ExcelService();
  
  // Create multiple test sales to verify row finding works correctly
  for (int i = 1; i <= 3; i++) {
    final testSaleData = {
      'saleId': 'TEST00$i',
      'date': '2024-01-15',
      'customerName': 'Test Customer $i',
      'items': [
        {
          'itemId': 'ITEM00$i',
          'itemName': 'Test Product $i',
          'quantity': i.toDouble(),
          'unit': 'pcs',
          'sellingPrice': (100.0 + i * 10), // VAT-inclusive
        }
      ],
      'saleType': 'Cash',
      'vatAmount': (i * 9.09), // Roughly 10% VAT
    };
    
    print('📝 Creating test sale $i...');
    try {
      bool result = await excelService.saveSaleToExcel(testSaleData);
      if (result) {
        print('✅ Test sale $i saved successfully');
      } else {
        print('❌ Test sale $i failed');
      }
    } catch (e) {
      print('❌ ERROR in test sale $i: $e');
    }
  }
  
  print('\n🏁 Row finding test completed!');
  print('Check your sales_records.xlsx file to verify:');
  print('- Data appears in consecutive rows');
  print('- No jumbled or overwritten data');
  print('- Headers remain intact');
}