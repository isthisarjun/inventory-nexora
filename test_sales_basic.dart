import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

void main() async {
  print('Testing Basic Sales System');
  
  try {
    // Test basic Excel functionality
    print('Creating test Excel file...');
    
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    
    final Sheet salesSheet = excel['Sales_Records'];
    
    // Create headers
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
    
    // Add headers
    for (var i = 0; i < headers.length; i++) {
      final cell = salesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
    }
    
    // Add sample data
    final sampleSaleData = {
      'Sale ID': 1001,
      'Date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'Customer Name': 'John Doe',
      'Item Name': 'Test Fabric',
      'Quantity Sold': 5,
      'Batch Cost Price': 10.0,
      'Selling Price': 15.0,
      'VAT Amount': 6.82,
      'Profit': 18.18
    };
    
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final cell = salesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = sampleSaleData[header];
    }
    
    // Get Documents directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/test_sales_records.xlsx';
    
    // Save file
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      
      print('✅ Test Excel file created successfully at: $filePath');
      
      // Read it back to verify
      final testFile = File(filePath);
      if (testFile.existsSync()) {
        final bytes = testFile.readAsBytesSync();
        final testExcel = Excel.decodeBytes(bytes);
        final testSheet = testExcel.tables['Sales_Records'];
        
        if (testSheet != null) {
          print('✅ Excel file read successfully');
          print('✅ Headers: ${testSheet.rows[0].map((cell) => cell?.value).toList()}');
          print('✅ Data: ${testSheet.rows[1].map((cell) => cell?.value).toList()}');
          
          // Test VAT calculation
          double sellingPrice = 15.0;
          double quantity = 5.0;
          double batchCost = 10.0;
          
          // VAT-inclusive calculation (10% VAT)
          double basePrice = sellingPrice / 1.10;
          double vatAmount = (basePrice * 0.10) * quantity;
          double profit = (basePrice - batchCost) * quantity;
          
          print('✅ VAT Calculations:');
          print('   Base Price: ${basePrice.toStringAsFixed(2)}');
          print('   VAT Amount: ${vatAmount.toStringAsFixed(2)}');
          print('   Profit: ${profit.toStringAsFixed(2)}');
          
        } else {
          print('❌ Could not read Sales_Records sheet');
        }
      } else {
        print('❌ Test file does not exist');
      }
    } else {
      print('❌ Could not save Excel file');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
