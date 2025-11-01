import 'lib/services/excel_service.dart';

void main() async {
  print('Testing unit cost fix...');
  
  final excelService = ExcelService();
  
  // Test data with fields from inventory screen
  final testItem = {
    'id': 'TEST_ITEM_${DateTime.now().millisecondsSinceEpoch}',
    'itemName': 'Test Item for Unit Cost',
    'supplier': 'Test Supplier',
    'unitCost': '25.500',  // This should map to costPrice
    'currentStock': '100', // This should map to quantity
    'minimumStock': '10',
  };
  
  print('Test item data: $testItem');
  print('unitCost: ${testItem['unitCost']}');
  print('currentStock: ${testItem['currentStock']}');
  
  try {
    // Save the test item
    await excelService.saveInventoryItemToExcel(testItem);
    print('✅ Item saved successfully');
    
    // Load inventory items to verify
    final items = await excelService.loadInventoryItemsFromExcel();
    final savedItem = items.firstWhere(
      (item) => item['id'] == testItem['id'],
      orElse: () => {},
    );
    
    if (savedItem.isNotEmpty) {
      print('✅ Item found in Excel');
      print('Saved cost price: ${savedItem['costPrice']}');
      print('Saved quantity: ${savedItem['quantity']}');
      
      // Check if values match
      final expectedCost = double.parse(testItem['unitCost']!);
      final actualCost = double.tryParse(savedItem['costPrice']?.toString() ?? '0') ?? 0.0;
      
      final expectedQuantity = double.parse(testItem['currentStock']!);
      final actualQuantity = double.tryParse(savedItem['quantity']?.toString() ?? '0') ?? 0.0;
      
      if (actualCost == expectedCost) {
        print('✅ Unit cost mapping FIXED! Expected: $expectedCost, Got: $actualCost');
      } else {
        print('❌ Unit cost mapping FAILED! Expected: $expectedCost, Got: $actualCost');
      }
      
      if (actualQuantity == expectedQuantity) {
        print('✅ Stock quantity mapping working! Expected: $expectedQuantity, Got: $actualQuantity');
      } else {
        print('❌ Stock quantity mapping failed! Expected: $expectedQuantity, Got: $actualQuantity');
      }
    } else {
      print('❌ Item not found in Excel');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
