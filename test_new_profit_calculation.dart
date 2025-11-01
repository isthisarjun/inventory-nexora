void main() {
  print('=== New Profit Calculation Test ===');
  print('Formula: (Selling Price - VAT - Batch Cost Price) × Quantity');
  print('Excel Formula: (Column H - Column I - Column G) × Quantity');
  
  // Test data
  final quantity = 2.0;
  final sellingPrice = 11.0;      // Column H - VAT-inclusive selling price
  final wacCostPrice = 8.0;       // Column G - Batch cost price
  final vatAmountTotal = 1.82;    // Column I - Total VAT amount for the sale
  
  print('\n--- Input Data ---');
  print('Quantity: $quantity');
  print('Selling Price (Column H): BHD $sellingPrice per unit');
  print('WAC Cost Price (Column G): BHD $wacCostPrice per unit');
  print('Total VAT Amount (Column I): BHD $vatAmountTotal for entire sale');
  
  // Calculate VAT per unit
  final vatAmountPerUnit = vatAmountTotal / quantity;
  print('VAT Amount per unit: BHD ${vatAmountPerUnit.toStringAsFixed(2)}');
  
  // Calculate profit using the new formula
  final profitPerUnit = sellingPrice - vatAmountPerUnit - wacCostPrice;
  final totalProfit = profitPerUnit * quantity;
  
  print('\n--- Profit Calculation ---');
  print('Profit per unit = Selling Price - VAT per unit - Batch Cost Price');
  print('Profit per unit = $sellingPrice - ${vatAmountPerUnit.toStringAsFixed(2)} - $wacCostPrice');
  print('Profit per unit = BHD ${profitPerUnit.toStringAsFixed(2)}');
  print('Total Profit = Profit per unit × Quantity');
  print('Total Profit = ${profitPerUnit.toStringAsFixed(2)} × $quantity');
  print('Total Profit = BHD ${totalProfit.toStringAsFixed(2)}');
  
  // Alternative calculation method (should be the same)
  final alternativeProfit = (sellingPrice * quantity) - vatAmountTotal - (wacCostPrice * quantity);
  print('\n--- Alternative Calculation ---');
  print('Total Profit = (Selling Price × Qty) - Total VAT - (Cost Price × Qty)');
  print('Total Profit = (${sellingPrice} × ${quantity}) - ${vatAmountTotal} - (${wacCostPrice} × ${quantity})');
  print('Total Profit = ${sellingPrice * quantity} - ${vatAmountTotal} - ${wacCostPrice * quantity}');
  print('Total Profit = BHD ${alternativeProfit.toStringAsFixed(2)}');
  
  // Verify both methods give the same result
  print('\n--- Verification ---');
  print('Method 1 Result: ${totalProfit.toStringAsFixed(2)} BHD');
  print('Method 2 Result: ${alternativeProfit.toStringAsFixed(2)} BHD');
  print('Match: ${(totalProfit - alternativeProfit).abs() < 0.01 ? "✅ YES" : "❌ NO"}');
  
  // Calculate profit margin
  final netSellingPrice = sellingPrice - vatAmountPerUnit;
  final profitMarginPercent = netSellingPrice > 0 ? (profitPerUnit / netSellingPrice) * 100 : 0.0;
  
  print('\n--- Profit Margin ---');
  print('Net Selling Price per unit (Selling - VAT): BHD ${netSellingPrice.toStringAsFixed(2)}');
  print('Profit Margin: ${profitMarginPercent.toStringAsFixed(1)}%');
  
  // Excel service simulation
  print('\n--- Excel Service Logic Test ---');
  final quantitySold = quantity;
  final totalCost = quantitySold * wacCostPrice;
  final totalSale = quantitySold * sellingPrice;
  
  final saleValues = [
    'TEST001',              // Sale ID
    '2025-09-16',          // Date
    'Test Customer',       // Customer Name
    'ITM001',              // Item ID
    'Test Item',           // Item Name
    quantitySold,          // Quantity Sold
    wacCostPrice,          // Column G - WAC Cost Price
    sellingPrice,          // Column H - Selling Price
    vatAmountTotal,        // Column I - VAT Amount
    totalProfit,           // Column J - Profit Amount (NEW FORMULA)
    totalCost,             // Column K - Total Cost
    totalSale,             // Column L - Total Sale
    profitMarginPercent,   // Column M - Profit Margin %
  ];
  
  print('Column J (Profit): ${saleValues[9]} BHD');
  print('Formula verification: (${saleValues[7]} - ${saleValues[8]}/${quantity} - ${saleValues[6]}) × ${quantity} = ${saleValues[9]}');
  
  print('\n=== Test Complete ===');
}