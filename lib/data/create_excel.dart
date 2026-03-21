import 'package:excel/excel.dart';
import 'dart:io';

void createInventoryCategoryManagementExcel() {
  // Create a new Excel document
  var excel = Excel.createExcel();

  // Add a sheet named "Item Category"
  Sheet? sheet = excel['Item Category'];

  // Save the file to the specified path
  String outputPath = 'lib/data/inventory_category_management.xlsx';
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(excel.encode()!);

   ('Excel file created at $outputPath');
}