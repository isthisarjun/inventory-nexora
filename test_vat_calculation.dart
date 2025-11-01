void main() {
  print('=== VAT-Inclusive Pricing Test ===');
  
  // Test the NEW VAT-inclusive calculation logic
  final quantity = 2.0;
  final unitPriceInclusiveVAT = 11.0; // This INCLUDES 10% VAT
  
  print('Quantity: $quantity');
  print('Unit Price (VAT-inclusive): BHD $unitPriceInclusiveVAT');
  
  if (quantity > 0 && unitPriceInclusiveVAT > 0) {
    // VAT-inclusive pricing: Unit Price includes 10% VAT
    // Base Price = Unit Price ÷ 1.10
    final basePrice = unitPriceInclusiveVAT / 1.10;
    final vatAmountPerUnit = basePrice * 0.10;
    final totalBasePrice = basePrice * quantity;
    final totalVATAmount = vatAmountPerUnit * quantity;
    final totalPrice = unitPriceInclusiveVAT * quantity;
    
    print('\n--- VAT-Inclusive Breakdown ---');
    print('Base Price per unit (excluding VAT): BHD ${basePrice.toStringAsFixed(2)}');
    print('VAT per unit (10%): BHD ${vatAmountPerUnit.toStringAsFixed(2)}');
    print('Unit Price (base + VAT): BHD ${(basePrice + vatAmountPerUnit).toStringAsFixed(2)}');
    
    print('\n--- Total Calculation ---');
    print('Total Base Price: BHD ${totalBasePrice.toStringAsFixed(2)}');
    print('Total VAT Amount: BHD ${totalVATAmount.toStringAsFixed(2)}');
    print('Total Price: BHD ${totalPrice.toStringAsFixed(2)}');
    print('Verification: ${(totalBasePrice + totalVATAmount).toStringAsFixed(2)} = ${totalPrice.toStringAsFixed(2)}');
    
    // Test Order Screen logic
    print('\n--- Order Screen Logic Test ---');
    final subtotal = totalPrice; // This is the sum of all item total prices
    final basePriceSubtotal = subtotal / 1.10;
    final vatAmount = basePriceSubtotal * 0.10;
    final finalPrice = subtotal; // VAT already included
    
    print('Subtotal (VAT-inclusive): BHD ${subtotal.toStringAsFixed(2)}');
    print('Base Price Subtotal: BHD ${basePriceSubtotal.toStringAsFixed(2)}');
    print('VAT Amount: BHD ${vatAmount.toStringAsFixed(2)}');
    print('Final Price: BHD ${finalPrice.toStringAsFixed(2)}');
    
    // Test the sale data structure
    final saleData = {
      'saleId': 'TEST002',
      'date': '2025-09-16',
      'customerName': 'Test Customer VAT',
      'vatAmount': vatAmount,
      'items': [
        {
          'itemId': 'ITM002',
          'itemName': 'Test VAT Item',
          'quantity': quantity,
          'sellingPrice': unitPriceInclusiveVAT,
        }
      ],
    };
    
    print('\n=== Sale Data Structure ===');
    print('VAT Amount in saleData: ${saleData['vatAmount']}');
    print('VAT Amount type: ${saleData['vatAmount'].runtimeType}');
    
    // Test type casting
    final vatAmountFromSale = (saleData['vatAmount'] as num?)?.toDouble() ?? 0.0;
    print('Extracted VAT Amount: $vatAmountFromSale');
    print('Extracted VAT Amount type: ${vatAmountFromSale.runtimeType}');
    
  } else {
    print('Invalid quantity or unit price');
  }
  
  print('\n=== Test Complete ===');
}