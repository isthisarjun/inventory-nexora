void main() {
  print('=== Column J: Selling Price Without VAT Test ===');
  
  // Test data
  final quantity = 2.0;
  final sellingPriceVATInclusive = 11.0;  // Column H - VAT-inclusive selling price
  final wacCostPrice = 8.0;               // Column G - Batch cost price
  final vatAmountTotal = 1.82;            // Column I - Total VAT amount for the sale
  
  print('--- Input Data ---');
  print('Quantity: $quantity');
  print('Selling Price (VAT-inclusive, Column H): BHD $sellingPriceVATInclusive per unit');
  print('WAC Cost Price (Column G): BHD $wacCostPrice per unit');
  print('Total VAT Amount (Column I): BHD $vatAmountTotal for entire sale');
  
  // Calculate VAT per unit and selling price without VAT
  final vatAmountPerUnit = vatAmountTotal / quantity;
  final sellingPriceWithoutVAT = sellingPriceVATInclusive - vatAmountPerUnit;
  final totalSellingPriceWithoutVAT = sellingPriceWithoutVAT * quantity;
  
  print('\n--- Column J Calculation ---');
  print('VAT Amount per unit: BHD ${vatAmountPerUnit.toStringAsFixed(2)}');
  print('Selling Price without VAT per unit: ${sellingPriceVATInclusive} - ${vatAmountPerUnit.toStringAsFixed(2)} = BHD ${sellingPriceWithoutVAT.toStringAsFixed(2)}');
  print('Total Selling Price without VAT (Column J): ${sellingPriceWithoutVAT.toStringAsFixed(2)} × ${quantity} = BHD ${totalSellingPriceWithoutVAT.toStringAsFixed(2)}');
  
  // Calculate profit using the selling price without VAT
  final profitPerUnit = sellingPriceWithoutVAT - wacCostPrice;
  final totalProfit = profitPerUnit * quantity;
  
  print('\n--- Profit Calculation (Now Column M) ---');
  print('Profit per unit = Selling Price (No VAT) - Cost Price');
  print('Profit per unit = ${sellingPriceWithoutVAT.toStringAsFixed(2)} - ${wacCostPrice} = BHD ${profitPerUnit.toStringAsFixed(2)}');
  print('Total Profit = ${profitPerUnit.toStringAsFixed(2)} × ${quantity} = BHD ${totalProfit.toStringAsFixed(2)}');
  
  // Calculate other totals
  final totalCost = quantity * wacCostPrice;
  final totalSale = quantity * sellingPriceVATInclusive;
  final profitMarginPercent = sellingPriceWithoutVAT > 0 ? (profitPerUnit / sellingPriceWithoutVAT) * 100 : 0.0;
  
  print('\n--- Complete Column Structure ---');
  final saleValues = [
    'TEST001',                        // A - Sale ID
    '2025-09-16',                    // B - Date  
    'Test Customer',                 // C - Customer Name
    'ITM001',                        // D - Item ID
    'Test Item',                     // E - Item Name
    quantity,                        // F - Quantity Sold
    wacCostPrice,                    // G - WAC Cost Price
    sellingPriceVATInclusive,        // H - Selling Price (VAT-inclusive)
    vatAmountTotal,                  // I - VAT Amount
    totalSellingPriceWithoutVAT,     // J - Selling Price (No VAT) ⭐ NEW
    totalCost,                       // K - Total Cost
    totalSale,                       // L - Total Sale
    totalProfit,                     // M - Profit Amount
    profitMarginPercent,             // N - Profit Margin %
  ];
  
  final headers = [
    'Sale ID', 'Date', 'Customer Name', 'Item ID', 'Item Name', 'Quantity Sold',
    'WAC Cost Price', 'Selling Price', 'VAT Amount', 'Selling Price (No VAT)',
    'Total Cost', 'Total Sale', 'Profit Amount', 'Profit Margin %'
  ];
  
  for (int i = 6; i < 10; i++) { // Focus on key columns G, H, I, J
    final columnLetter = String.fromCharCode(65 + i);
    print('Column $columnLetter (index $i): ${headers[i]} = ${saleValues[i]}');
  }
  
  print('\n--- Key Verification ---');
  print('Column H (Selling Price VAT-incl): ${saleValues[7]} BHD');
  print('Column I (VAT Amount): ${saleValues[8]} BHD');
  print('Column J (Selling Price No VAT): ${saleValues[9]} BHD');
  print('Formula: Column J = (Column H - Column I/Qty) × Qty');
  print('Verification: (${saleValues[7]} - ${saleValues[8]}/${quantity}) × ${quantity} = ${saleValues[9]}');
  
  // Verify the calculation
  final calculatedJ = ((saleValues[7] as double) - (saleValues[8] as double) / quantity) * quantity;
  print('Calculated: ${calculatedJ.toStringAsFixed(2)}');
  print('Match: ${((saleValues[9] as double) - calculatedJ).abs() < 0.01 ? "✅ YES" : "❌ NO"}');
  
  print('\n=== Test Complete ===');
}