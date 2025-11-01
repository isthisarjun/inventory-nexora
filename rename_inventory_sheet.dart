import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('Starting Excel sheet renaming process...');
  
  try {
    final directory = await getApplicationDocumentsDirectory();
    final originalFilePath = '${directory.path}/inventory_items.xlsx';
    final newFilePath = '${directory.path}/inventory_purchase_details.xlsx';
    final blankFilePath = '${directory.path}/inventory_items.xlsx';
    
    final originalFile = File(originalFilePath);
    
    // Step 1: Check if the original file exists
    if (!await originalFile.exists()) {
      print('❌ Original inventory_items.xlsx file does not exist at: $originalFilePath');
      print('Creating a new blank inventory_items.xlsx file instead...');
      await createBlankInventoryItemsFile(blankFilePath);
      return;
    }
    
    print('✅ Found existing inventory_items.xlsx file');
    
    // Step 2: Read the existing file
    final bytes = await originalFile.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    print('📊 File structure:');
    for (String sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      print('  - Sheet: "$sheetName" (${sheet?.maxRows ?? 0} rows, ${sheet?.maxCols ?? 0} columns)');
    }
    
    // Step 3: Rename to inventory_purchase_details.xlsx
    print('\n🔄 Renaming inventory_items.xlsx to inventory_purchase_details.xlsx...');
    final newFile = File(newFilePath);
    await originalFile.copy(newFilePath);
    
    if (await newFile.exists()) {
      print('✅ Successfully created inventory_purchase_details.xlsx');
      
      // Delete the original file
      await originalFile.delete();
      print('✅ Original inventory_items.xlsx file removed');
    } else {
      print('❌ Failed to create inventory_purchase_details.xlsx');
      return;
    }
    
    // Step 4: Create a new blank inventory_items.xlsx
    print('\n📄 Creating new blank inventory_items.xlsx...');
    await createBlankInventoryItemsFile(blankFilePath);
    
    print('\n🎉 Process completed successfully!');
    print('📂 Files created:');
    print('  1. inventory_purchase_details.xlsx (renamed from original)');
    print('  2. inventory_items.xlsx (new blank file)');
    
    // Verify the files
    print('\n🔍 Verification:');
    final purchaseFile = File(newFilePath);
    final itemsFile = File(blankFilePath);
    
    if (await purchaseFile.exists()) {
      print('✅ inventory_purchase_details.xlsx exists');
    } else {
      print('❌ inventory_purchase_details.xlsx missing');
    }
    
    if (await itemsFile.exists()) {
      print('✅ inventory_items.xlsx exists');
    } else {
      print('❌ inventory_items.xlsx missing');
    }
    
  } catch (e) {
    print('❌ Error during renaming process: $e');
  }
}

/// Create a new blank inventory_items.xlsx file with proper structure
Future<void> createBlankInventoryItemsFile(String filePath) async {
  try {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Items sheet
    final Sheet itemsSheet = excel['Items'];
    
    // Add column headers
    final headers = [
      'Item ID',
      'Name',
      'Category',
      'Description',
      'SKU',
      'Barcode',
      'Unit',
      'Current Stock',
      'Minimum Stock',
      'Maximum Stock',
      'Unit Cost',
      'Selling Price',
      'Supplier',
      'Location',
      'Status',
      'Date Added',
      'Last Updated',
      'Notes',
    ];
    
    // Set headers in the first row
    for (int i = 0; i < headers.length; i++) {
      final cell = itemsSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#E3F2FD',
        fontColorHex: '#1976D2',
      );
    }
    
    // Set column widths for better readability
    for (var i = 0; i < headers.length; i++) {
      itemsSheet.setColWidth(i, 15.0);
    }
    
    // Save the file
    final excelBytes = excel.save();
    if (excelBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);
      print('✅ Created new blank inventory_items.xlsx with proper structure');
    } else {
      print('❌ Failed to generate Excel file bytes');
    }
    
  } catch (e) {
    print('❌ Error creating blank inventory_items.xlsx: $e');
  }
}
