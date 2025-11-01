import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  print('Testing expense Excel sheet creation...');
  
  try {
    // Create a simple Excel file for expenses
    var excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create expenses sheet
    var sheet = excel['expenses'];
    
    // Set headers
    sheet.cell(CellIndex.indexByString("A1")).value = 'Expense ID';
    sheet.cell(CellIndex.indexByString("B1")).value = 'Date';
    sheet.cell(CellIndex.indexByString("C1")).value = 'Description';
    sheet.cell(CellIndex.indexByString("D1")).value = 'Amount';
    sheet.cell(CellIndex.indexByString("E1")).value = 'Category';
    sheet.cell(CellIndex.indexByString("F1")).value = 'Payment Method';
    sheet.cell(CellIndex.indexByString("G1")).value = 'Vendor';
    sheet.cell(CellIndex.indexByString("H1")).value = 'Reference';
    
    // Add sample expense record
    sheet.cell(CellIndex.indexByString("A2")).value = 'EXP001';
    sheet.cell(CellIndex.indexByString("B2")).value = '2024-01-15';
    sheet.cell(CellIndex.indexByString("C2")).value = 'Office Supplies';
    sheet.cell(CellIndex.indexByString("D2")).value = 150.00;
    sheet.cell(CellIndex.indexByString("E2")).value = 'Office Supplies';
    sheet.cell(CellIndex.indexByString("F2")).value = 'Cash';
    sheet.cell(CellIndex.indexByString("G2")).value = 'Office Depot';
    sheet.cell(CellIndex.indexByString("H2")).value = 'INV-2024-001';
    
    // Save the file
    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      File(r'c:\TwentyFiveProj\inventory_v1\expenses.xlsx')
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      
      print('✅ expenses.xlsx created successfully!');
      print('File location: c:\\TwentyFiveProj\\inventory_v1\\expenses.xlsx');
      
      // Verify file exists and has content
      var file = File(r'c:\TwentyFiveProj\inventory_v1\expenses.xlsx');
      if (file.existsSync()) {
        print('✅ File exists and size: ${file.lengthSync()} bytes');
        
        // Read back the file to verify
        var bytes = file.readAsBytesSync();
        var excelRead = Excel.decodeBytes(bytes);
        
        if (excelRead.tables.containsKey('expenses')) {
          var readSheet = excelRead.tables['expenses'];
          var headerCell = readSheet?.cell(CellIndex.indexByString("A1"));
          var dataCell = readSheet?.cell(CellIndex.indexByString("A2"));
          
          print('✅ Sheet "expenses" found');
          print('✅ Header A1: ${headerCell?.value}');
          print('✅ Data A2: ${dataCell?.value}');
          print('✅ Expense tracking system verified!');
        }
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
