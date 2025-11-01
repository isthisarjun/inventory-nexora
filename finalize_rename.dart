import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
   ('Finalizing Excel sheet renaming process...');
  
  try {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null) {
      print('❌ Could not find user profile directory');
      return;
    }
    
    final documentsPath = '$userProfile\\Documents';
    final originalFilePath = '$documentsPath\\inventory_items.xlsx';
    final newFilePath = '$documentsPath\\inventory_purchase_details.xlsx';
    final tempFilePath = '$documentsPath\\inventory_items_temp.xlsx';
    
    // Check current state
    final originalFile = File(originalFilePath);
    final newFile = File(newFilePath);
    
    print('📊 Current file status:');
    print('  inventory_items.xlsx: ${await originalFile.exists() ? "EXISTS" : "MISSING"}');
    print('  inventory_purchase_details.xlsx: ${await newFile.exists() ? "EXISTS" : "MISSING"}');
    
    if (!await newFile.exists()) {
      print('❌ inventory_purchase_details.xlsx is missing. Please run the rename script first.');
      return;
    }
    
    // Create new blank inventory_items.xlsx with a temporary name first
    print('\\n📄 Creating new blank inventory_items.xlsx...');
    await createBlankInventoryItemsFile(tempFilePath);
    
    if (await originalFile.exists()) {
      // Try to replace the original file
      try {
        // Try to delete the original
        await originalFile.delete();
        print('✅ Successfully deleted original inventory_items.xlsx');
        
        // Move temp file to original location
        final tempFile = File(tempFilePath);
        await tempFile.rename(originalFilePath);
        print('✅ New blank inventory_items.xlsx created successfully');
        
      } catch (e) {
        print('⚠️  Could not replace original file: $e');
        print('\\n🔧 Alternative approach:');
        
        // Use PowerShell to handle the file operations
        await _handleFileReplacementWithPowerShell(originalFilePath, tempFilePath);
      }
    } else {
      // Original doesn't exist, just rename temp to original
      final tempFile = File(tempFilePath);
      await tempFile.rename(originalFilePath);
      print('✅ Created new inventory_items.xlsx');
    }
    
    // Final verification
    print('\\n🔍 Final verification:');
    final finalOriginal = File(originalFilePath);
    final finalNew = File(newFilePath);
    
    if (await finalNew.exists()) {
      print('✅ inventory_purchase_details.xlsx: Contains original data');
    }
    
    if (await finalOriginal.exists()) {
      // Check if it's truly a blank file
      final bytes = await finalOriginal.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables['Items'];
      
      if (sheet != null && sheet.maxRows <= 1) {
        print('✅ inventory_items.xlsx: New blank file ready for use');
      } else {
        print('⚠️  inventory_items.xlsx: Still contains old data');
      }
    } else {
      print('❌ inventory_items.xlsx: Missing');
    }
    
    print('\\n🎉 Process completed!');
    print('\\n📋 Summary:');
    print('• inventory_purchase_details.xlsx = Your original purchase data');
    print('• inventory_items.xlsx = New blank file for item management');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> _handleFileReplacementWithPowerShell(String originalPath, String tempPath) async {
  try {
    print('🔧 Using PowerShell to handle file replacement...');
    
    // Create a PowerShell script to handle the file operations
    final scriptContent = r'''
$originalPath = "''' + originalPath + r'''"
$tempPath = "''' + tempPath + r'''"

# Kill any Excel processes that might be locking the file
Get-Process | Where-Object {$_.ProcessName -like "*excel*" -or $_.ProcessName -like "*office*"} | ForEach-Object {
    try {
        Stop-Process $_.Id -Force
        Write-Host "Stopped process: $_.ProcessName ($_.Id)"
    } catch {
        Write-Host "Could not stop process: $_.ProcessName"
    }
}

Start-Sleep -Seconds 2

# Try to delete the original file
try {
    Remove-Item $originalPath -Force
    Write-Host "Deleted original file"
    
    # Move temp file to original location
    Move-Item $tempPath $originalPath
    Write-Host "Moved new file to original location"
    
} catch {
    Write-Host "Error replacing file: $_"
    Write-Host "Manual intervention required"
}
''';
    
    final scriptFile = File('${Platform.environment['TEMP']}\\replace_inventory_file.ps1');
    await scriptFile.writeAsString(scriptContent);
    
    final result = await Process.run('powershell', [
      '-ExecutionPolicy', 'Bypass',
      '-File', scriptFile.path
    ]);
    
    print('PowerShell output: ${result.stdout}');
    if (result.stderr.isNotEmpty) {
      print('PowerShell errors: ${result.stderr}');
    }
    
    // Clean up script file
    await scriptFile.delete();
    
  } catch (e) {
    print('❌ PowerShell approach failed: $e');
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
      print('✅ Created blank Excel file at: $filePath');
    } else {
      print('❌ Failed to generate Excel file bytes');
    }
    
  } catch (e) {
    print('❌ Error creating blank file: $e');
  }
}
