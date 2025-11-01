void main() {
  print('=== Profit Calculation Test ===');
  
  // Test data
  final quantity = 2.0;
  final sellingPriceVATInclusive = 11.0; // BHD 11.00 (includes 10% VAT)
  final costPrice = 8.0; // BHD 8.00 (WAC cost from inventory)
  
  print('Quantity: $quantity');
  print('Selling Price (VAT-inclusive): BHD $sellingPriceVATInclusive');
  print('Cost Price (WAC): BHD $costPrice');
  
  // Calculate VAT-exclusive base price
  final baseSellingPrice = sellingPriceVATInclusive / 1.10;
  print('Base Selling Price (VAT-exclusive): BHD ${baseSellingPrice.toStringAsFixed(2)}');
  
  // Calculate profit using correct formula
  final profitPerUnit = baseSellingPrice - costPrice;
  final totalProfit = profitPerUnit * quantity;
  
  print('\n--- Profit Calculation ---');
  print('Profit per unit: BHD ${profitPerUnit.toStringAsFixed(2)} (${baseSellingPrice.toStringAsFixed(2)} - ${costPrice.toStringAsFixed(2)})');
  print('Total Profit: BHD ${totalProfit.toStringAsFixed(2)} (${profitPerUnit.toStringAsFixed(2)} × $quantity)');
  
  // Calculate profit margin percentage (based on VAT-exclusive base price)
  final totalBaseSale = baseSellingPrice * quantity;
  final profitMarginPercent = totalBaseSale > 0 ? (totalProfit / totalBaseSale) * 100 : 0.0;
  print('Profit Margin: ${profitMarginPercent.toStringAsFixed(1)}% (${totalProfit.toStringAsFixed(2)} ÷ ${totalBaseSale.toStringAsFixed(2)} × 100)');
  
  // Excel service calculations (should match)
  print('\n--- Excel Service Logic ---');
  final quantitySold = quantity;
  final sellingPrice = sellingPriceVATInclusive;
  final wacCostPrice = costPrice;
  
  final totalCost = quantitySold * wacCostPrice;
  final totalSale = quantitySold * sellingPrice; // VAT-inclusive
  final totalBaseSaleExcel = quantitySold * (sellingPrice / 1.10); // VAT-exclusive
  final profitExcel = totalBaseSaleExcel - totalCost;
  final profitMarginPercentExcel = totalBaseSaleExcel > 0 ? (profitExcel / totalBaseSaleExcel) * 100 : 0.0;
  
  print('Total Cost: BHD ${totalCost.toStringAsFixed(2)}');
  print('Total Sale (VAT-incl): BHD ${totalSale.toStringAsFixed(2)}');
  print('Total Base Sale (VAT-excl): BHD ${totalBaseSaleExcel.toStringAsFixed(2)}');
  print('Profit (Excel): BHD ${profitExcel.toStringAsFixed(2)}');
  print('Profit Margin (Excel): ${profitMarginPercentExcel.toStringAsFixed(1)}%');
  
  // Verify calculations match
  print('\n--- Verification ---');
  print('Manual Total Profit: ${totalProfit.toStringAsFixed(2)} BHD');
  print('Excel Total Profit:  ${profitExcel.toStringAsFixed(2)} BHD');
  print('Match: ${(totalProfit - profitExcel).abs() < 0.01 ? "✅ YES" : "❌ NO"}');
  
  print('\n=== Test Complete ===');
}