import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  print('Starting Sales Records Excel header fix...');
  
  try {
    await fixSalesRecordsExcelHeaders();
    print('Sales Records Excel header fix completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> fixSalesRecordsExcelHeaders() async {
  final file = File('sales_records.xlsx');
  
  if (!file.existsSync()) {
    print('File sales_records.xlsx not found! Creating sample file...');
    await createSampleSalesRecordsFile();
    return;
  }

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  
  // Get or create sheet
  Sheet sheet;
  if (excel.tables.containsKey('Sheet1')) {
    sheet = excel['Sheet1'];
  } else {
    sheet = excel[excel.tables.keys.first];
  }
  
  // Fix headers to match expected format
  sheet.updateCell(CellIndex.indexByString('A1'), 'Sale ID');
  sheet.updateCell(CellIndex.indexByString('B1'), 'Date');
  sheet.updateCell(CellIndex.indexByString('C1'), 'Customer Name');
  sheet.updateCell(CellIndex.indexByString('D1'), 'Item Name');
  sheet.updateCell(CellIndex.indexByString('E1'), 'Quantity Sold');
  sheet.updateCell(CellIndex.indexByString('F1'), 'Batch Cost Price');
  sheet.updateCell(CellIndex.indexByString('G1'), 'Selling Price');
  sheet.updateCell(CellIndex.indexByString('H1'), 'VAT Amount');
  sheet.updateCell(CellIndex.indexByString('I1'), 'Profit');
  
  print('Fixed headers in sales_records.xlsx');
  
  // Save the updated file
  final List<int> newBytes = excel.encode()!;
  await file.writeAsBytes(newBytes);
  
  print('sales_records.xlsx updated successfully!');
}

Future<void> createSampleSalesRecordsFile() async {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  
  // Set headers
  sheet.updateCell(CellIndex.indexByString('A1'), 'Sale ID');
  sheet.updateCell(CellIndex.indexByString('B1'), 'Date');
  sheet.updateCell(CellIndex.indexByString('C1'), 'Customer Name');
  sheet.updateCell(CellIndex.indexByString('D1'), 'Item Name');
  sheet.updateCell(CellIndex.indexByString('E1'), 'Quantity Sold');
  sheet.updateCell(CellIndex.indexByString('F1'), 'Batch Cost Price');
  sheet.updateCell(CellIndex.indexByString('G1'), 'Selling Price');
  sheet.updateCell(CellIndex.indexByString('H1'), 'VAT Amount');
  sheet.updateCell(CellIndex.indexByString('I1'), 'Profit');
  
  // Add sample data starting from Sale ID 1001
  sheet.updateCell(CellIndex.indexByString('A2'), '1001');
  sheet.updateCell(CellIndex.indexByString('B2'), '2024-01-15');
  sheet.updateCell(CellIndex.indexByString('C2'), 'John Smith');
  sheet.updateCell(CellIndex.indexByString('D2'), 'Sample Item');
  sheet.updateCell(CellIndex.indexByString('E2'), '2');
  sheet.updateCell(CellIndex.indexByString('F2'), '45.45'); // Base cost
  sheet.updateCell(CellIndex.indexByString('G2'), '55.00'); // VAT-inclusive selling price
  sheet.updateCell(CellIndex.indexByString('H2'), '10.00'); // VAT amount (50.00 base * 0.10 * 2 qty)
  sheet.updateCell(CellIndex.indexByString('I2'), '9.10'); // Profit ((50.00 - 45.45) * 2)
  
  sheet.updateCell(CellIndex.indexByString('A3'), '1002');
  sheet.updateCell(CellIndex.indexByString('B3'), '2024-01-16');
  sheet.updateCell(CellIndex.indexByString('C3'), 'Jane Doe');
  sheet.updateCell(CellIndex.indexByString('D3'), 'Another Item');
  sheet.updateCell(CellIndex.indexByString('E3'), '1');
  sheet.updateCell(CellIndex.indexByString('F3'), '27.27');
  sheet.updateCell(CellIndex.indexByString('G3'), '33.00');
  sheet.updateCell(CellIndex.indexByString('H3'), '3.00');
  sheet.updateCell(CellIndex.indexByString('I3'), '2.73');
  
  final List<int> bytes = excel.encode()!;
  final file = File('sales_records.xlsx');
  await file.writeAsBytes(bytes);
  
  print('Created sample sales_records.xlsx with proper headers and sample data');
}
