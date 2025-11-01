import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  print('Starting Excel sheet renaming process...');
  
  try {
    // Use a common Documents path for Windows
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null) {
      print('❌ Could not find user profile directory');
      return;
    }
    
    final documentsPath = '$userProfile\\Documents';
    final originalFilePath = '$documentsPath\\inventory_items.xlsx';
    final newFilePath = '$documentsPath\\inventory_purchase_details.xlsx';
    final backupFilePath = '$documentsPath\\inventory_items_backup.xlsx';
    
    final originalFile = File(originalFilePath);
    
    // Step 1: Check if the original file exists
    if (!await originalFile.exists()) {
      print('❌ Original inventory_items.xlsx file does not exist at: $originalFilePath');
      print('Creating a new blank inventory_items.xlsx file instead...');
      await createBlankInventoryItemsFile(originalFilePath);
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
    
    // Step 3: Create inventory_purchase_details.xlsx (copy of original)
    print('\\n🔄 Creating inventory_purchase_details.xlsx...');
    final newFile = File(newFilePath);
    await originalFile.copy(newFilePath);
    
    if (await newFile.exists()) {
      print('✅ Successfully created inventory_purchase_details.xlsx');
    } else {
      print('❌ Failed to create inventory_purchase_details.xlsx');
      return;
    }
    
    // Step 4: Create backup of original (in case of deletion issues)
    print('\\n💾 Creating backup of original file...');
    await originalFile.copy(backupFilePath);
    print('✅ Backup created: inventory_items_backup.xlsx');
    
    // Step 5: Try to delete original and create new blank file
    try {
      await originalFile.delete();
      print('✅ Original inventory_items.xlsx file removed');
      
      // Create new blank inventory_items.xlsx
      print('\\n📄 Creating new blank inventory_items.xlsx...');
      await createBlankInventoryItemsFile(originalFilePath);
      
    } catch (deleteError) {
      print('⚠️  Could not delete original file (might be open in Excel)');
      print('   Error: $deleteError');
      print('\\n📋 Manual steps required:');
      print('   1. Close Excel if inventory_items.xlsx is open');
      print('   2. Delete inventory_items.xlsx manually');
      print('   3. Run this script again, or:');
      print('   4. Rename inventory_items_backup.xlsx to inventory_items.xlsx');
      print('      and create a new blank inventory_items.xlsx file');
    }
    
    print('\\n🎉 Process completed!');
    print('📂 Files status:');
    
    // Verify the files
    final purchaseFile = File(newFilePath);
    final itemsFile = File(originalFilePath);
    final backupFile = File(backupFilePath);
    
    if (await purchaseFile.exists()) {
      print('✅ inventory_purchase_details.xlsx exists (renamed from original)');
    } else {
      print('❌ inventory_purchase_details.xlsx missing');
    }
    
    if (await itemsFile.exists()) {
      final itemsBytes = await itemsFile.readAsBytes();
      final itemsExcel = Excel.decodeBytes(itemsBytes);
      
      // Check if it's the new blank file or the old file
      bool hasData = false;
      if (itemsExcel.tables['Items'] != null) {
        final sheet = itemsExcel.tables['Items']!;
        hasData = sheet.maxRows > 1; // More than just headers
      }
      
      if (hasData) {
        print('⚠️  inventory_items.xlsx exists but contains old data');
        print('   Please manually delete it and rename inventory_items_backup.xlsx');
      } else {
        print('✅ inventory_items.xlsx exists (new blank file)');
      }
    } else {
      print('❌ inventory_items.xlsx missing - creating new blank file...');
      await createBlankInventoryItemsFile(originalFilePath);
    }
    
    if (await backupFile.exists()) {
      print('📁 inventory_items_backup.xlsx exists (safety backup)');
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
