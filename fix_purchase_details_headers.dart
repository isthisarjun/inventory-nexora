import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';

void main() async {
  print('Starting Purchase Details Excel header fix...');
  
  try {
    await fixPurchaseDetailsExcelHeaders();
    print('Purchase Details Excel header fix completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> fixPurchaseDetailsExcelHeaders() async {
  final file = File('inventory_purchase_details.xlsx');
  
  if (!file.existsSync()) {
    print('File inventory_purchase_details.xlsx not found! Creating sample file...');
    
    // Create a sample Excel file with purchase data but no headers
    final sampleExcel = Excel.createExcel();
    final sampleSheet = sampleExcel['Sheet1'];
    
    // Add sample purchase data without headers
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'PURCH001';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = '2024-01-15';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'VEND001';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = 'ABC Supplier';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = 'ITEM001';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = 'Cotton Fabric';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = 50;
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value = 25.50;
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0)).value = 1275.00;
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0)).value = 'Paid';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0)).value = 'Premium quality material';
    
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'PURCH002';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = '2024-01-16';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = 'VEND002';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1)).value = 'XYZ Textiles';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1)).value = 'ITEM002';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1)).value = 'Silk Thread';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1)).value = 100;
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1)).value = 12.75;
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1)).value = 1275.00;
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1)).value = 'Pending';
    sampleSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 1)).value = 'Regular order';
    
    final sampleBytes = sampleExcel.encode()!;
    file.writeAsBytesSync(sampleBytes);
    print('Sample purchase details file created with test data.');
  }

  print('Reading Purchase Details Excel file...');
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  
  // Get the sheet name (could be 'Sheet1' or 'Purchase_Details')
  final sheetName = excel.tables.keys.first;
  final sheet = excel.tables[sheetName]!;
  
  print('Sheet name: $sheetName');
  print('Total rows: ${sheet.rows.length}');
  
  // Find maximum column count
  int maxCols = 0;
  for (var row in sheet.rows) {
    if (row.length > maxCols) {
      maxCols = row.length;
    }
  }
  print('Total columns: $maxCols');
  
  // Check if headers already exist (first row contains purchase-related headers)
  bool hasHeaders = false;
  if (sheet.rows.isNotEmpty) {
    final firstRow = sheet.rows.first;
    if (firstRow.isNotEmpty && firstRow.first?.value != null) {
      final firstCellValue = firstRow.first!.value.toString().toLowerCase();
      hasHeaders = firstCellValue.contains('purchase') || 
                   firstCellValue.contains('id') || 
                   firstCellValue.contains('vendor') ||
                   firstCellValue.contains('item') ||
                   firstCellValue.contains('date');
    }
  }
  
  if (hasHeaders) {
    print('Headers already exist:');
    final firstRow = sheet.rows.first;
    for (int i = 0; i < firstRow.length; i++) {
      final cell = firstRow[i];
      if (cell?.value != null) {
        print('Column ${i + 1}: ${cell!.value.toString()}');
      }
    }
    return;
  }
  
  print('No headers found. Analyzing purchase data structure...');
  
  // Define purchase details headers based on your system structure
  List<String> purchaseHeaders = [
    'Purchase ID',
    'Date', 
    'Vendor ID',
    'Vendor Name',
    'Item ID',
    'Item Name',
    'Quantity',
    'Cost Price',
    'Total Amount',
    'Payment Status',
    'Notes'
  ];
  
  // Adjust headers if there are more/fewer columns
  if (maxCols < purchaseHeaders.length) {
    purchaseHeaders = purchaseHeaders.take(maxCols).toList();
  }
  
  while (purchaseHeaders.length < maxCols) {
    purchaseHeaders.add('Extra Field ${purchaseHeaders.length - 10}');
  }
  
  // Analyze sample data
  print('Sample purchase data analysis:');
  for (int col = 0; col < min(maxCols, purchaseHeaders.length); col++) {
    List<String> sampleValues = [];
    for (int row = 0; row < min(3, sheet.rows.length); row++) {
      if (col < sheet.rows[row].length) {
        final cell = sheet.rows[row][col];
        if (cell?.value != null) {
          sampleValues.add(cell!.value.toString());
        }
      }
    }
    
    if (sampleValues.isNotEmpty) {
      print('Column ${col + 1} (${purchaseHeaders[col]}): ${sampleValues.join(', ')}');
    }
  }
  
  // Create new Excel file with headers
  print('Adding purchase headers...');
  
  // Create a completely new Excel file
  final newExcel = Excel.createExcel();
  newExcel.delete('Sheet1'); // Remove default sheet
  final newSheet = newExcel['Purchase_Details'];
  
  // Add header row with styling
  for (int col = 0; col < purchaseHeaders.length; col++) {
    final cell = newSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
    cell.value = purchaseHeaders[col];
    cell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#4CAF50',
      fontColorHex: '#FFFFFF',
    );
  }
  
  // Copy existing data starting from row 1
  for (int rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
    final sourceRow = sheet.rows[rowIndex];
    for (int colIndex = 0; colIndex < sourceRow.length; colIndex++) {
      final sourceCell = sourceRow[colIndex];
      if (sourceCell?.value != null) {
        final targetCell = newSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: colIndex,
          rowIndex: rowIndex + 1  // +1 because we added header row
        ));
        // Copy the value directly without referencing the cell object
        final cellValue = sourceCell!.value;
        if (cellValue is String) {
          targetCell.value = cellValue;
        } else if (cellValue is int) {
          targetCell.value = cellValue;
        } else if (cellValue is double) {
          targetCell.value = cellValue;
        } else {
          targetCell.value = cellValue.toString();
        }
      }
    }
  }
  
  // Save the updated file
  print('Saving updated purchase details file...');
  final updatedBytes = newExcel.encode()!;
  file.writeAsBytesSync(updatedBytes);
  
  print('Purchase Details headers added successfully!');
  print('Header row:');
  for (int i = 0; i < purchaseHeaders.length; i++) {
    print('  ${i + 1}. ${purchaseHeaders[i]}');
  }
}
