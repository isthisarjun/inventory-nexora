void main() {
  print('=== Sales Records Column Mapping Test ===');
  
  // Test the saleValues array structure
  final saleId = 'TEST001';
  final date = '2025-09-16';
  final customerName = 'Test Customer';
  final itemId = 'ITM001';
  final itemName = 'Test Item';
  final quantitySold = 2.0;
  final wacCostPrice = 8.0;       // Should go to Column G (index 6)
  final sellingPrice = 11.0;      // Should go to Column H (index 7)
  final vatAmount = 1.82;         // Should go to Column I (index 8)
  final totalCost = 16.0;
  final totalSale = 22.0;
  final profit = 4.0;
  final profitMarginPercent = 20.0;
  
  final saleValues = [
    saleId,
    date,
    customerName,
    itemId,
    itemName,
    quantitySold,
    wacCostPrice,           // Column G (index 6) - Batch Cost Price
    sellingPrice,           // Column H (index 7) - Selling Price
    vatAmount,              // Column I (index 8) - VAT Amount
    totalCost,
    totalSale,
    profit,
    profitMarginPercent,
  ];
  
  final headers = [
    'Sale ID',
    'Date',
    'Customer Name',
    'Item ID',
    'Item Name',
    'Quantity Sold',
    'WAC Cost Price',       // Column G (index 6)
    'Selling Price',        // Column H (index 7)
    'VAT Amount',           // Column I (index 8)
    'Total Cost',
    'Total Sale',
    'Profit Amount',
    'Profit Margin %',
  ];
  
  print('\n--- Column Mapping Verification ---');
  for (int i = 0; i < headers.length; i++) {
    final columnLetter = String.fromCharCode(65 + i); // A=65, B=66, etc.
    print('Column $columnLetter (index $i): ${headers[i]} = ${saleValues[i]}');
  }
  
  print('\n--- Key Columns Verification ---');
  print('Column G (index 6): WAC Cost Price = ${saleValues[6]} BHD');
  print('Column H (index 7): Selling Price = ${saleValues[7]} BHD');
  print('Column I (index 8): VAT Amount = ${saleValues[8]} BHD');
  
  print('\n--- Expected vs Actual ---');
  print('Expected Column G: WAC Cost Price (8.0) | Actual: ${saleValues[6]}');
  print('Expected Column H: Selling Price (11.0) | Actual: ${saleValues[7]}');
  print('Expected Column I: VAT Amount (1.82) | Actual: ${saleValues[8]}');
  
  final gCorrect = saleValues[6] == wacCostPrice;
  final hCorrect = saleValues[7] == sellingPrice;
  final iCorrect = saleValues[8] == vatAmount;
  
  print('\n--- Verification Results ---');
  print('Column G (WAC Cost Price): ${gCorrect ? "✅ CORRECT" : "❌ WRONG"}');
  print('Column H (Selling Price): ${hCorrect ? "✅ CORRECT" : "❌ WRONG"}');
  print('Column I (VAT Amount): ${iCorrect ? "✅ CORRECT" : "❌ WRONG"}');
  
  print('\n=== Test Complete ===');
}