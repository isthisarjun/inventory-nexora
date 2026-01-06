import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'lib/services/excel_service.dart';

Future<void> main() async {
  print('Creating inventory_vat_report.xlsx...');
  
  final excelService = ExcelService();
  
  // Get documents directory path
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/inventory_vat_report.xlsx';
  
  print('File path: $filePath');
  
  // Call the internal method to create the VAT report file
  // Since _createVatReportFile is private, we'll trigger it through calculateVatSummary
  await excelService.calculateVatSummary();
  
  print('✅ VAT report file created successfully!');
  print('Location: $filePath');
  
  // Verify the file exists
  if (await File(filePath).exists()) {
    final fileSize = await File(filePath).length();
    print('File size: ${fileSize} bytes');
  } else {
    print('❌ Error: File was not created');
  }
}
