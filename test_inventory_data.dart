import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

Future<void> testInventoryData() async {
  try {
    print('🧪 Starting inventory data test...');
    
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/inventory_items.xlsx';
    final file = File(filePath);
    
    print('📁 File path: $filePath');
    print('📁 File exists: ${file.existsSync()}');
    
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      print('📊 Excel sheets: ${excel.sheets.keys}');
      
      if (excel.sheets.containsKey('Items')) {
        final sheet = excel.sheets['Items']!;
        print('📋 Sheet rows: ${sheet.maxRows}');
        print('📋 Sheet cols: ${sheet.maxCols}');
        
        // Print first few rows
        for (int i = 0; i < (sheet.maxRows > 5 ? 5 : sheet.maxRows); i++) {
          final row = sheet.row(i);
          print('Row $i: ${row.map((cell) => cell?.value?.toString() ?? 'null').join(' | ')}');
        }
      } else {
        print('❌ "Items" sheet not found');
        print('Available sheets: ${excel.sheets.keys}');
      }
    } else {
      print('❌ File does not exist');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

void main() async {
  await testInventoryData();
}