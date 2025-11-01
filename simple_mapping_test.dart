void main() {
  print('Testing field mapping logic...');
  
  // Simulate the mapping logic we added to excel_service.dart
  Map<String, dynamic> item = {
    'unitCost': '25.500',     // From inventory screen
    'currentStock': '100',    // From inventory screen  
    'costPrice': null,        // Excel field (currently null)
    'quantity': null,         // Excel field (currently null)
  };
  
  print('Original item data: $item');
  
  // Apply the mapping logic we added
  final newQuantity = double.tryParse(item['quantity']?.toString() ?? item['currentStock']?.toString() ?? '0') ?? 0.0;
  final newCostPrice = double.tryParse(item['costPrice']?.toString() ?? item['unitCost']?.toString() ?? '0') ?? 0.0;
  
  print('Mapped quantity: $newQuantity (should be 100.0)');
  print('Mapped cost price: $newCostPrice (should be 25.5)');
  
  if (newQuantity == 100.0 && newCostPrice == 25.5) {
    print('✅ Field mapping works correctly!');
  } else {
    print('❌ Field mapping failed!');
  }
}
