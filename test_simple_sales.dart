import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

void main() async {
  print('Testing Simple Sales System...');
  
  try {
    // Test: Create a simple sale record with the format from the user's requirements
    await testSimpleSaleCreation();
    print('✅ Simple sale creation test completed!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> testSimpleSaleCreation() async {
  // Get the Documents directory
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/sales_records.xlsx');
  
  Excel excel;
  
  if (file.existsSync()) {
    print('📄 Loading existing sales_records.xlsx file...');
    final bytes = file.readAsBytesSync();
    excel = Excel.decodeBytes(bytes);
  } else {
    print('📄 Creating new sales_records.xlsx file...');
    excel = Excel.createExcel();
    excel.delete('Sheet1');
    
    // Create sales sheet with user's specified structure
    final sheet = excel['Sheet1'];
    
    // Headers: Sale ID, Date, Customer Name, Item Name, Quantity Sold, Batch Cost Price, Selling Price, VAT Amount, Profit
    final headers = [
      'Sale ID',
      'Date', 
      'Customer Name',
      'Item Name',
      'Quantity Sold',
      'Batch Cost Price',
      'Selling Price',
      'VAT Amount',
      'Profit'
    ];
    
    // Set headers
    for (int i = 0; i < headers.length; i++) {
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0), headers[i]);
    }
  }
  
  final sheet = excel['Sheet1'];
  
  // Get next Sale ID (starting from 1001)
  int nextSaleId = 1001;
  for (int i = 1; i < sheet.maxRows; i++) {
    final row = sheet.row(i);
    if (row.isNotEmpty && row[0]?.value != null) {
      try {
        final saleId = int.parse(row[0]!.value.toString());
        if (saleId >= nextSaleId) {
          nextSaleId = saleId + 1;
        }
      } catch (e) {
        // Skip invalid IDs
      }
    }
  }
  
  // Create test sale data with 10% VAT inclusive pricing
  final sellingPrice = 55.0; // VAT-inclusive price
  final basePrice = sellingPrice / 1.10; // Base price = 50.00
  final quantity = 2.0;
  final batchCostPrice = 30.0; // Cost price from inventory
  final vatAmount = (basePrice * 0.10) * quantity; // VAT = (50.00 * 0.10) * 2 = 10.00
  final profit = (basePrice - batchCostPrice) * quantity; // Profit = (50.00 - 30.00) * 2 = 40.00
  
  print('💰 Sale Calculation Details:');
  print('   Selling Price (VAT-incl): $sellingPrice BHD');
  print('   Base Price (VAT-excl): ${basePrice.toStringAsFixed(2)} BHD');
  print('   Quantity: $quantity');
  print('   Batch Cost: $batchCostPrice BHD');
  print('   VAT Amount: ${vatAmount.toStringAsFixed(2)} BHD');
  print('   Profit: ${profit.toStringAsFixed(2)} BHD');
  
  // Find next empty row
  int nextRow = sheet.maxRows;
  
  // Add sale data
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: nextRow), nextSaleId.toString());
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: nextRow), DateFormat('yyyy-MM-dd').format(DateTime.now()));
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: nextRow), 'Test Customer');
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: nextRow), 'Test Item');
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: nextRow), quantity);
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: nextRow), batchCostPrice);
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: nextRow), sellingPrice);
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: nextRow), vatAmount);
  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: nextRow), profit);
  
  // Save file
  final List<int> newBytes = excel.encode()!;
  await file.writeAsBytes(newBytes);
  
  print('✅ Sale #$nextSaleId created successfully!');
  print('📂 File saved to: ${file.path}');
}
