import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import '../models/customer.dart';

class ExcelService {
  // Singleton pattern
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  static ExcelService get instance => _instance;
  ExcelService._internal();

  // Initialize a new empty Excel file with proper structure
  Excel initializeExcelFile() {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Orders sheet
    final Sheet ordersSheet = excel['Orders'];
    
    // Add column headers
    final headers = [
      'Order ID',
      'Customer Name',
      'Customer ID',
      'Order Date',
      'Due Date',
      'Items',
      'Total Amount',
      'Paid Amount',
      'Status',
      'Priority',
      'Assigned To',
      'Notes',
      'Payment Method',
    ];
    
    // Add header styling
    for (var i = 0; i < headers.length; i++) {
      final cell = ordersSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: '#4CAF50',
        fontColorHex: '#FFFFFF',
      );
    }
    
    // Set column widths for better readability
    for (var i = 0; i < headers.length; i++) {
      ordersSheet.setColWidth(i, 15.0);
    }
    
    return excel;
  }

  // Generate a template file for order imports
  Future<String> generateOrderTemplate() async {
    final excel = initializeExcelFile();
    
    // Save the file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/inventory_orders_template.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);
    
    return path;
  }

  // Import orders from Excel file
  Future<List<Map<String, dynamic>>> importOrdersFromExcel() async {
    final List<Map<String, dynamic>> orders = [];
    
    // Pick Excel file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    
    if (result == null) return orders;
    
    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    // Get the Orders sheet (or first sheet if not found)
    final sheetName = excel.tables.keys.contains('Orders') ? 'Orders' : excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;
    
    // Get headers to allow for flexible column order
    final headerRow = sheet.rows[0];
    final headers = <String, int>{};
    
    for (var i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value != null) {
        headers[cell!.value.toString()] = i;
      }
    }
    
    // Process data rows (skip header)
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      
      // Skip empty rows
      if (row.isEmpty || row[0]?.value == null) continue;
      
      try {
        final order = <String, dynamic>{};
        
        // Map Excel columns to order properties
        order['id'] = _getCellValue(row, headers, 'Order ID') ?? 
            'ORD-${DateTime.now().millisecondsSinceEpoch}';
        order['customerName'] = _getCellValue(row, headers, 'Customer Name') ?? 'Unknown';
        order['customerId'] = _getCellValue(row, headers, 'Customer ID') ?? '';
        order['orderDate'] = _parseDateValue(row, headers, 'Order Date') ?? DateTime.now();
        order['dueDate'] = _parseDateValue(row, headers, 'Due Date') ?? 
            DateTime.now().add(const Duration(days: 7));
        order['items'] = _parseItemsList(row, headers, 'Items');
        order['totalAmount'] = _parseDoubleValue(row, headers, 'Total Amount') ?? 0.0;
        order['paidAmount'] = _parseDoubleValue(row, headers, 'Paid Amount') ?? 0.0;
        order['status'] = _getCellValue(row, headers, 'Status')?.toLowerCase() ?? 'pending';
        order['priority'] = _getCellValue(row, headers, 'Priority')?.toLowerCase() ?? 'medium';
        order['assignedTo'] = _getCellValue(row, headers, 'Assigned To') ?? 'Unassigned';
        order['notes'] = _getCellValue(row, headers, 'Notes') ?? '';
        
        orders.add(order);
      } catch (e) {
        print('Error processing row $i: $e');
        // Continue with next row
      }
    }
    
    return orders;
  }
  
  // Export orders to Excel file
  Future<String> exportOrdersToExcel(List<Map<String, dynamic>> orders) async {
    final excel = initializeExcelFile();
    final Sheet sheet = excel['Orders'];
    
    // Add data rows
    for (var i = 0; i < orders.length; i++) {
      final order = orders[i];
      final rowIndex = i + 1; // Skip header row
      
      _setCellValue(sheet, 0, rowIndex, order['id']);
      _setCellValue(sheet, 1, rowIndex, order['customerName']);
      _setCellValue(sheet, 2, rowIndex, order['customerId']);
      _setCellValue(sheet, 3, rowIndex, DateFormat('yyyy-MM-dd').format(order['orderDate']));
      _setCellValue(sheet, 4, rowIndex, DateFormat('yyyy-MM-dd').format(order['dueDate']));
      _setCellValue(sheet, 5, rowIndex, (order['items'] as List).join(', '));
      _setCellValue(sheet, 6, rowIndex, order['totalAmount'].toString());
      _setCellValue(sheet, 7, rowIndex, order['paidAmount'].toString());
      _setCellValue(sheet, 8, rowIndex, order['status']);
      _setCellValue(sheet, 9, rowIndex, order['priority']);
      _setCellValue(sheet, 10, rowIndex, order['assignedTo']);
      _setCellValue(sheet, 11, rowIndex, order['notes'] ?? '');
    }
    
    // Save the file
    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/inventory_orders_$now.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);
    
    return path;
  }
  
  // Import customers from Excel file
  Future<List<Map<String, dynamic>>> importCustomersFromExcel() async {
    List<Map<String, dynamic>> customers = [];
    
    try {
      // Show file picker to select Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      
      if (result != null) {
        // Read file bytes
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        
        // Parse Excel file
        var excel = Excel.decodeBytes(bytes);
        var sheet = excel['Customers']; // Make sure your Excel file has a 'Customers' sheet
        
        // Skip header row
        for (var row = 1; row < sheet.maxRows; row++) {
          // Read customer data from each row
          String id = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value?.toString() ?? '';
          String name = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value?.toString() ?? '';
          String phone = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value?.toString() ?? '';
          String email = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value?.toString() ?? '';
          String address = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value?.toString() ?? '';
          
          // Create customer map and add to list
          if (id.isNotEmpty && name.isNotEmpty) {
            customers.add({
              'id': id,
              'name': name,
              'phone': phone,
              'phoneNumber': phone, // Keep both for compatibility
              'email': email,
              'address': address,
            });
          }
        }
      }
    } catch (e) {
      print('Error importing customers: $e');
    }
    
    return customers;
  }
  
  // Load customers from inventory_customer_list.xlsx file (without file picker)
  Future<List<Map<String, dynamic>>> loadCustomersFromFile() async {
    List<Map<String, dynamic>> customers = [];
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_customer_list.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Customer list file does not exist');
        return customers;
      }
      
      // Read the existing Excel file
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // Check if customer_list sheet exists
      if (!excel.tables.containsKey('customer_list')) {
        print('customer_list sheet does not exist');
        return customers;
      }
      
      final sheet = excel['customer_list'];
      
      // Skip header row and read customer data
      for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        
        // Skip empty rows
        if (row.isEmpty) continue;
        
        // Read customer data from each column
        String id = row.length > 0 ? (row[0]?.value?.toString() ?? '') : '';
        String name = row.length > 1 ? (row[1]?.value?.toString() ?? '') : '';
        String phone = row.length > 2 ? (row[2]?.value?.toString() ?? '') : '';
        String email = row.length > 3 ? (row[3]?.value?.toString() ?? '') : '';
        String address = row.length > 4 ? (row[4]?.value?.toString() ?? '') : '';
        
        // Only add if we have at least a name and phone
        if (name.isNotEmpty && phone.isNotEmpty) {
          customers.add({
            'id': id.isNotEmpty ? id : 'CUST-${DateTime.now().millisecondsSinceEpoch}',
            'name': name,
            'phone': phone,
            'phoneNumber': phone, // Keep both for compatibility
            'email': email,
            'address': address,
          });
        }
      }
    } catch (e) {
      print('Error loading customers from file: $e');
    }
    
    return customers;
  }
  
  // Export customers to Excel file
  Future<bool> exportCustomersToExcel(List<Customer> customers) async {
    try {
      // Create a new Excel file
      final excel = Excel.createExcel();
      
      // Remove default sheet
      excel.delete('Sheet1');
      
      // Create Customers sheet
      final Sheet customerSheet = excel['Customers'];
      
      // Add headers
      final headers = ['Customer ID', 'Name', 'Phone Number', 'Address', 'Email'];
      for (var i = 0; i < headers.length; i++) {
        final cell = customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: '#4CAF50',
          fontColorHex: '#FFFFFF',
        );
      }
      
      // Add customer data
      for (var i = 0; i < customers.length; i++) {
        final customer = customers[i];
        customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = customer.id;
        customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = customer.name;
        customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = customer.phoneNumber;
        customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
            .value = customer.address ?? '';
        customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
            .value = customer.email ?? '';
      }
      
      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'inventory_customers_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      // Save the Excel file
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      // Show file save success dialog or open file
      return true;
    } catch (e) {
      print('Error exporting customers: $e');
      return false;
    }
  }
  
  // Add this method to handle Map-based customer data
  Future<String> exportCustomersMapToExcel(List<Map<String, dynamic>> customers) async {
    try {
      // Create a new Excel file
      final excel = Excel.createExcel();
      
      // Remove default sheet
      excel.delete('Sheet1');
      
      // Create Customers sheet
      final Sheet customerSheet = excel['Customers'];
      
      // Add headers
      final headers = ['ID', 'Name', 'Phone', 'Email', 'Address'];
      for (var i = 0; i < headers.length; i++) {
        final cell = customerSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: '#4CAF50',
          fontColorHex: '#FFFFFF',
        );
      }
      
      // Add customer data
      for (var i = 0; i < customers.length; i++) {
        final customer = customers[i];
        final rowIndex = i + 1;
        
        _setCellValue(customerSheet, 0, rowIndex, customer['id']?.toString() ?? '');
        _setCellValue(customerSheet, 1, rowIndex, customer['name']?.toString() ?? '');
        _setCellValue(customerSheet, 2, rowIndex, customer['phone']?.toString() ?? '');
        _setCellValue(customerSheet, 3, rowIndex, customer['email']?.toString() ?? '');
        _setCellValue(customerSheet, 4, rowIndex, customer['address']?.toString() ?? '');
      }
      
      // Save the file
      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/inventory_customers_$now.xlsx';
      final file = File(path);
      await file.writeAsBytes(excel.encode()!);
      
      return path;
    } catch (e) {
      print('Error exporting customers: $e');
      throw Exception('Failed to export customers: $e');
    }
  }
  
  // Clear all customers from inventory_customer_list.xlsx
  Future<bool> clearAllCustomers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_customer_list.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Customer list file does not exist');
        return false;
      }
      
      // Read the existing Excel file
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // Check if customer_list sheet exists
      if (!excel.tables.containsKey('customer_list')) {
        print('customer_list sheet does not exist');
        return false;
      }
      
      final sheet = excel['customer_list'];
      
      // Clear all rows except the header (row 0)
      final maxRows = sheet.maxRows;
      for (int rowIndex = 1; rowIndex < maxRows; rowIndex++) {
        // Get the row and clear each cell
        final row = sheet.row(rowIndex);
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheet.updateCell(
            CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
            null,
          );
        }
      }
      
      // Save the updated Excel file
      final newBytes = excel.encode();
      if (newBytes != null) {
        await file.writeAsBytes(newBytes);
        print('All customers cleared successfully');
        return true;
      } else {
        print('Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('Error clearing customers: $e');
      return false;
    }
  }

  // Helper methods
  String? _getCellValue(List<Data?> row, Map<String, int> headers, String columnName) {
    if (!headers.containsKey(columnName)) return null;
    final colIndex = headers[columnName]!;
    return row.length > colIndex ? row[colIndex]?.value?.toString() : null;
  }
  
  double? _parseDoubleValue(List<Data?> row, Map<String, int> headers, String columnName) {
    final value = _getCellValue(row, headers, columnName);
    if (value == null) return null;
    
    final cleaned = value.replaceAll('BHD', '').replaceAll('\$', '').replaceAll(',', '').trim();
    try {
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }
  
  DateTime? _parseDateValue(List<Data?> row, Map<String, int> headers, String columnName) {
    final dateStr = _getCellValue(row, headers, columnName);
    if (dateStr == null) return null;
    return _parseDate(dateStr);
  }
  
  List<String> _parseItemsList(List<Data?> row, Map<String, int> headers, String columnName) {
    final itemsStr = _getCellValue(row, headers, columnName) ?? '';
    return itemsStr.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }
  
  void _setCellValue(Sheet sheet, int col, int row, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
      .value = value;
  }
  
  DateTime _parseDate(String dateStr) {
    try {
      // Try standard format first
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try common formats
        final formats = [
          'yyyy-MM-dd',
          'dd/MM/yyyy',
          'MM/dd/yyyy',
          'dd-MM-yyyy',
          'MM-dd-yyyy',
        ];
        
        for (final format in formats) {
          try {
            return DateFormat(format).parse(dateStr);
          } catch (_) {
            // Try next format
          }
        }
        
        // Default to current date if all parsing fails
        return DateTime.now();
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  // Placeholder methods for missing functionality
  // TODO: Implement these methods properly
  
  // This is an alias for the file-based customer loading method
  Future<List<Map<String, dynamic>>> loadCustomersFromExcel() async {
    return await loadCustomersFromFile();
  }
  
  Future<List<Map<String, dynamic>>> loadOrdersFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/inventory_orders_template.xlsx');
      
      if (!await file.exists()) {
        print('Orders file does not exist yet');
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Orders'];
      
      List<Map<String, dynamic>> orders = [];
      
      if (sheet.maxRows > 1) {
        // Skip header row (first row)
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.isNotEmpty && row[0]?.value != null) {
            // Safely access columns with bounds checking
            orders.add({
              'orderId': row.length > 0 ? row[0]?.value?.toString() ?? '' : '',
              'customerName': row.length > 1 ? row[1]?.value?.toString() ?? '' : '', // Fixed: Customer name is in column 1
              'customerId': row.length > 1 ? row[1]?.value?.toString() ?? '' : '', // Also store as customerId for compatibility
              'orderDate': row.length > 3 ? row[3]?.value?.toString() ?? '' : '', // Fixed: Order date is in column 3
              'date': row.length > 3 ? row[3]?.value?.toString() ?? '' : '', // Alias for compatibility
              'dueDate': row.length > 4 ? row[4]?.value?.toString() ?? '' : '', // Fixed: Due date is in column 4
              'items': row.length > 5 ? row[5]?.value?.toString() ?? '' : '', // Fixed: Items are in column 5
              'totalCost': row.length > 6 ? double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0 : 0.0, // Fixed: Total cost in column 6
              'totalAmount': row.length > 6 ? double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0 : 0.0, // Alias for compatibility
              'materials': row.length > 7 ? row[7]?.value?.toString() ?? '' : '',
              'materialsCost': row.length > 8 ? double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0.0 : 0.0,
              'labourCost': row.length > 9 ? double.tryParse(row[9]?.value?.toString() ?? '0') ?? 0.0 : 0.0,
              'advanceAmount': row.length > 10 ? double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0 : 0.0,
              'status': row.length > 11 ? row[11]?.value?.toString() ?? 'pending' : 'pending',
              'paymentStatus': row.length > 12 ? row[12]?.value?.toString() ?? 'pay_at_delivery' : 'pay_at_delivery',
              'paymentMethod': row.length > 13 ? row[13]?.value?.toString() ?? '' : '', // Added for payment method
              'vatAmount': row.length > 14 ? double.tryParse(row[14]?.value?.toString() ?? '0') ?? 0.0 : 0.0,
              'includeVat': row.length > 15 ? row[15]?.value?.toString().toLowerCase() == 'true' : false,
            });
          }
        }
      }
      
      return orders;
    } catch (e) {
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> loadMaterialStockFromExcel() async {
    // TODO: Implement material loading - load from inventory_materials_stock.xlsx
    return [];
  }
  
  Future<List<Map<String, dynamic>>> loadVendorsFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_vendors.xlsx';
      
      final file = File(filePath);
      if (!await file.exists()) {
        await _createVendorsFile(filePath);
        return [];
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final sheet = excel['Vendors'];

      final List<Map<String, dynamic>> vendorsList = [];
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
        
        try {
          final vendor = {
            'vendorId': row[0]?.value?.toString() ?? '',
            'vendorName': row[1]?.value?.toString() ?? '',
            'email': row[2]?.value?.toString() ?? '',
            'phone': row[3]?.value?.toString() ?? '',
            'address': row[4]?.value?.toString() ?? '',
            'city': row[5]?.value?.toString() ?? '',
            'country': row[6]?.value?.toString() ?? '',
            'vatNumber': row[7]?.value?.toString() ?? '',
            'maximumCredit': _parseDoubleValue(row, {'Maximum Credit (BHD)': 8}, 'Maximum Credit (BHD)') ?? 0.0,
            'currentCredit': _parseDoubleValue(row, {'Current Credit (BHD)': 9}, 'Current Credit (BHD)') ?? 0.0,
            'notes': row[10]?.value?.toString() ?? '',
            'status': row[11]?.value?.toString() ?? 'Active',
            'dateAdded': row[12]?.value?.toString() ?? '',
            'totalPurchases': _parseDoubleValue(row, {'Total Purchases': 13}, 'Total Purchases') ?? 0.0,
            'lastPurchaseDate': row[14]?.value?.toString() ?? '',
          };
          
          vendorsList.add(vendor);
        } catch (e) {
          // Skip invalid row
          continue;
        }
      }
      
      return vendorsList;
      
    } catch (e) {
      return [];
    }
  }

  // ========== INVENTORY ITEMS MANAGEMENT ==========
  
  /// Load all inventory items from inventory_items.xlsx and aggregate by Item ID
  Future<List<Map<String, dynamic>>> loadInventoryItemsFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      print('🔍 DEBUG: Looking for inventory file at: $filePath');
      print('🔍 DEBUG: File exists: ${file.existsSync()}');
      
      if (!await file.exists()) {
        // Create the file with proper structure if it doesn't exist
        await _createInventoryItemsFile(filePath);
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      print('🔍 DEBUG: Excel sheets: ${excel.sheets.keys}');
      
      // Check if 'Items' sheet exists
      if (!excel.sheets.containsKey('Items')) {
        print('❌ ERROR: "Items" sheet not found in inventory_items.xlsx');
        return [];
      }
      
      final sheet = excel.sheets['Items']!;
      final rows = sheet.rows;
      
      print('🔍 DEBUG: Sheet has ${rows.length} rows');
      
      if (rows.length <= 1) {
        print('⚠️ DEBUG: No data rows found (only headers)');
        return [];
      }
      
      Map<String, Map<String, dynamic>> aggregatedItems = {};
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        // Ensure row has minimum required columns before accessing
        if (row.length < 11) {
          print('Skipping row $rowIndex: insufficient columns (${row.length})');
          continue;
        }
        
        final itemId = row[0]?.value?.toString() ?? '';
        final quantity = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;  // Quantity Purchased
        final costPrice = double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0; // Cost Price
        
        if (aggregatedItems.containsKey(itemId)) {
          // Add to existing item - aggregate quantities and recalculate weighted average cost
          final existing = aggregatedItems[itemId]!;
          final existingQty = existing['currentStock'] as double;
          final existingCost = existing['unitCost'] as double;
          
          final newTotalQty = existingQty + quantity;
          final newWeightedCost = newTotalQty > 0 
            ? ((existingQty * existingCost) + (quantity * costPrice)) / newTotalQty
            : 0.0;
          
          existing['currentStock'] = newTotalQty;
          existing['unitCost'] = newWeightedCost;
          existing['lastUpdated'] = (row.length > 16 && row[16]?.value != null) 
              ? row[16]!.value!.toString() 
              : DateTime.now().toIso8601String();
        } else {
          // Create new aggregated item with safe column access
          aggregatedItems[itemId] = {
            'id': itemId,
            'name': row[1]?.value?.toString() ?? '',
            'category': row[2]?.value?.toString() ?? '',
            'description': (row.length > 3 && row[3]?.value != null) ? row[3]!.value!.toString() : '',
            'sku': (row.length > 4 && row[4]?.value != null) ? row[4]!.value!.toString() : '',
            'barcode': (row.length > 5 && row[5]?.value != null) ? row[5]!.value!.toString() : '',
            'unit': (row.length > 6 && row[6]?.value != null) ? row[6]!.value!.toString() : 'pcs',
            'currentStock': quantity,
            'minimumStock': (row.length > 8 && row[8]?.value != null) 
                ? double.tryParse(row[8]!.value!.toString()) ?? 0.0 
                : 0.0,
            'maximumStock': (row.length > 9 && row[9]?.value != null) 
                ? double.tryParse(row[9]!.value!.toString()) ?? 0.0 
                : 0.0,
            'unitCost': costPrice,
            'sellingPrice': (row.length > 11 && row[11]?.value != null) 
                ? double.tryParse(row[11]!.value!.toString()) ?? 0.0 
                : 0.0,
            'supplier': (row.length > 12 && row[12]?.value != null) ? row[12]!.value!.toString() : '',
            'location': (row.length > 13 && row[13]?.value != null) ? row[13]!.value!.toString() : '',
            'status': (row.length > 14 && row[14]?.value != null) ? row[14]!.value!.toString() : 'Active',
            'dateAdded': (row.length > 15 && row[15]?.value != null) 
                ? row[15]!.value!.toString() 
                : DateTime.now().toIso8601String(),
            'lastUpdated': (row.length > 16 && row[16]?.value != null) 
                ? row[16]!.value!.toString() 
                : DateTime.now().toIso8601String(),
            'notes': (row.length > 17 && row[17]?.value != null) ? row[17]!.value!.toString() : '',
          };
        }
      }
      
      // Convert to list and sort alphabetically by item name
      final itemsList = aggregatedItems.values.toList();
      itemsList.sort((a, b) {
        final nameA = (a['name'] as String? ?? '').toLowerCase();
        final nameB = (b['name'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });
      
      print('🔤 Items sorted alphabetically by name');
      return itemsList;
    } catch (e) {
      return [];
    }
  }
  
  /// Get all purchase entries from inventory_purchase_details.xlsx without aggregation
  /// Returns raw purchase records sorted by purchase date (newest first)
  Future<List<Map<String, dynamic>>> getAllPurchaseEntries() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_purchase_details.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        // Return empty list if purchase details file doesn't exist yet
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Purchase_Details'];
      
      List<Map<String, dynamic>> purchaseEntries = [];
      
      // Skip header row (row 0)
      // Columns: Purchase Id, Vendor Name, Items, Number of Items, Unit Cost, Payment Status, Date of Order
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        // Ensure row has minimum required columns before accessing
        if (row.length < 7) {
          print('Skipping row $rowIndex: insufficient columns (${row.length})');
          continue;
        }
        
        purchaseEntries.add({
          'purchaseId': row[0]?.value?.toString() ?? '',                 // Purchase Id
          'vendorName': row[1]?.value?.toString() ?? '',                 // Vendor Name  
          'items': row[2]?.value?.toString() ?? '',                      // Items
          'numberOfItems': row[3]?.value?.toString() ?? '',              // Number of Items
          'unitCost': row[4]?.value?.toString() ?? '',                   // Unit Cost
          'paymentStatus': row[5]?.value?.toString() ?? '',              // Payment Status
          'dateOfOrder': row[6]?.value?.toString() ?? '',                // Date of Order
        });
      }
      
      // Sort by date of order (newest first)
      purchaseEntries.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['dateOfOrder']);
          final dateB = DateTime.parse(b['dateOfOrder']);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          return 0;
        }
      });
      
      return purchaseEntries;
    } catch (e) {
      print('Error loading purchase entries: $e');
      return [];
    }
  }
  
  /// Save a new inventory purchase entry to inventory_items.xlsx
  /// Uses Weighted Average Cost (WAC) logic for existing items
  Future<bool> saveInventoryItemToExcel(Map<String, dynamic> item) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      Excel excel;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = await _createInventoryItemsFile(filePath);
      }
      
      final sheet = excel['Items'];
      
      // Generate new ID if not provided
      if (item['id'] == null || item['id'].toString().isEmpty) {
        item['id'] = 'ITM${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Add timestamps
      final now = DateTime.now().toIso8601String();
      item['purchaseDate'] = item['purchaseDate'] ?? now;
      item['lastUpdated'] = now;
      
      // Map field names from inventory screen to Excel format
      final newQuantity = double.tryParse(item['quantity']?.toString() ?? item['currentStock']?.toString() ?? '0') ?? 0.0;
      final newCostPrice = double.tryParse(item['costPrice']?.toString() ?? item['unitCost']?.toString() ?? '0') ?? 0.0;
      final itemName = item['name']?.toString() ?? '';
      final itemSku = item['sku']?.toString() ?? '';
      
      // Check if item already exists (by name or SKU)
      List<int> existingRowsIndexes = [];
      double totalExistingQuantity = 0.0;
      double totalExistingValue = 0.0;
      
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        final existingName = row[1]?.value?.toString() ?? '';
        final existingSku = row[4]?.value?.toString() ?? '';
        final existingQuantity = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
        final existingCostPrice = double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0;
        
        // Match by name or SKU (if both are not empty)
        bool isMatch = false;
        if (itemName.isNotEmpty && existingName.isNotEmpty && existingName.toLowerCase() == itemName.toLowerCase()) {
          isMatch = true;
        } else if (itemSku.isNotEmpty && existingSku.isNotEmpty && existingSku == itemSku) {
          isMatch = true;
        }
        
        if (isMatch && existingQuantity > 0) {
          existingRowsIndexes.add(rowIndex);
          totalExistingQuantity += existingQuantity;
          totalExistingValue += (existingQuantity * existingCostPrice);
        }
      }
      
      // Calculate Weighted Average Cost if existing stock found
      double finalCostPrice = newCostPrice;
      if (existingRowsIndexes.isNotEmpty && totalExistingQuantity > 0) {
        final newValue = newQuantity * newCostPrice;
        final totalValue = totalExistingValue + newValue;
        final totalQuantity = totalExistingQuantity + newQuantity;
        
        if (totalQuantity > 0) {
          finalCostPrice = totalValue / totalQuantity;
          
          // Update all existing rows with the new weighted average cost
          for (int rowIndex in existingRowsIndexes) {
            final costCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex));
            costCell.value = finalCostPrice;
            
            // Update last updated timestamp
            final lastUpdatedCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex));
            lastUpdatedCell.value = now;
          }
          
          print('WAC applied: Existing qty: ${totalExistingQuantity.toStringAsFixed(2)}, '
                'New qty: ${newQuantity.toStringAsFixed(2)}, '
                'Old avg cost: ${totalExistingQuantity > 0 ? (totalExistingValue / totalExistingQuantity).toStringAsFixed(2) : "0.00"}, '
                'New cost: ${newCostPrice.toStringAsFixed(2)}, '
                'WAC: ${finalCostPrice.toStringAsFixed(2)}');
        }
      }
      
      // Find next empty row for the new purchase entry
      int nextRow = sheet.maxRows;
      
      // Add the new purchase entry with WAC cost price
      final rowData = [
        item['id'],
        item['name'] ?? '',
        item['category'] ?? '',
        item['description'] ?? '',
        item['sku'] ?? '',
        item['barcode'] ?? '',
        item['unit'] ?? 'pcs',
        newQuantity,
        item['minimumStock'] ?? 0.0,
        item['maximumStock'] ?? 0.0,
        finalCostPrice,  // Use WAC cost price
        item['sellingPrice'] ?? 0.0,
        item['supplier'] ?? '',
        item['location'] ?? '',
        item['status'] ?? 'Active',
        item['purchaseDate'],
        item['lastUpdated'],
        item['notes'] ?? '',
      ];
      
      for (int i = 0; i < rowData.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: nextRow)).value = rowData[i];
      }

      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        
        // Also save this purchase as a transaction for expense tracking
        final totalPurchaseAmount = newQuantity * newCostPrice;
        await saveTransactionToExcel(
          transactionType: 'purchase',
          partyName: item['supplier']?.toString().trim().isNotEmpty == true 
              ? item['supplier'] 
              : 'Unknown Supplier',
          amount: -totalPurchaseAmount, // Negative amount for expense
          description: 'Purchase of ${newQuantity}x ${item['name'] ?? 'Unknown Item'}',
          reference: item['id']?.toString() ?? '',
          category: 'Inventory Purchase',
          transactionDate: item['purchaseDate'] != null 
              ? DateTime.tryParse(item['purchaseDate'].toString()) ?? DateTime.now()
              : DateTime.now(),
          vatRate: null, // No VAT for purchases in this context
          vatAmount: null,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error saving inventory purchase entry with WAC: $e');
      return false;
    }
  }
  
  /// Add stock to an existing item by creating a new purchase entry
  /// This method creates a new row in the Excel sheet with the same Item ID but different cost price
  Future<bool> addStockPurchaseEntry({
    required String itemId,
    required double quantity,
    required double costPrice,
    String supplier = '',
    String notes = '',
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Inventory file does not exist');
        return false;
      }
      
      // Get the item details from existing entries
      final existingItems = await loadInventoryItemsFromExcel();
      final existingItem = existingItems.firstWhere(
        (item) => item['id'] == itemId,
        orElse: () => {},
      );
      
      if (existingItem.isEmpty) {
        print('Item with ID $itemId not found');
        return false;
      }
      
      // Create a new purchase entry with the same item details but new cost price and quantity
      final purchaseEntry = {
        'id': itemId,
        'name': existingItem['name'],
        'category': existingItem['category'],
        'description': existingItem['description'],
        'sku': existingItem['sku'],
        'barcode': existingItem['barcode'],
        'unit': existingItem['unit'],
        'quantity': quantity,
        'minimumStock': existingItem['minimumStock'],
        'maximumStock': existingItem['maximumStock'],
        'costPrice': costPrice,
        'sellingPrice': existingItem['sellingPrice'],
        'supplier': supplier.isNotEmpty ? supplier : existingItem['supplier'],
        'location': existingItem['location'],
        'status': existingItem['status'],
        'notes': notes,
      };
      
      // Save the new purchase entry
      return await saveInventoryItemToExcel(purchaseEntry);
    } catch (e) {
      print('Error adding stock purchase entry: $e');
      return false;
    }
  }
  
  /// Update an existing inventory item
  Future<bool> updateInventoryItemInExcel(String itemId, Map<String, dynamic> updatedItem) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        return false;
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      // Find the item to update
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value?.toString() != itemId) continue;
        
        // Update the item data
        updatedItem['lastUpdated'] = DateTime.now().toIso8601String();
        
        final rowData = [
          itemId,
          updatedItem['name'] ?? row[1]?.value?.toString() ?? '',
          updatedItem['category'] ?? row[2]?.value?.toString() ?? '',
          updatedItem['description'] ?? row[3]?.value?.toString() ?? '',
          updatedItem['sku'] ?? row[4]?.value?.toString() ?? '',
          updatedItem['barcode'] ?? row[5]?.value?.toString() ?? '',
          updatedItem['unit'] ?? row[6]?.value?.toString() ?? 'pcs',
          updatedItem['currentStock'] ?? double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0,
          updatedItem['minimumStock'] ?? double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0.0,
          updatedItem['maximumStock'] ?? double.tryParse(row[9]?.value?.toString() ?? '0') ?? 0.0,
          updatedItem['unitCost'] ?? double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0,
          updatedItem['sellingPrice'] ?? double.tryParse(row[11]?.value?.toString() ?? '0') ?? 0.0,
          updatedItem['supplier'] ?? (row.length > 12 ? row[12]?.value?.toString() : '') ?? '',
          updatedItem['location'] ?? (row.length > 13 ? row[13]?.value?.toString() : '') ?? '',
          updatedItem['status'] ?? (row.length > 14 ? row[14]?.value?.toString() : 'Active') ?? 'Active',
          (row.length > 15 ? row[15]?.value?.toString() : null) ?? DateTime.now().toIso8601String(), // Keep original dateAdded
          updatedItem['lastUpdated'],
          updatedItem['notes'] ?? (row.length > 17 ? row[17]?.value?.toString() : '') ?? '',
        ];
        
        for (int i = 0; i < rowData.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).value = rowData[i];
        }
        
        // Save the file
        final excelBytes = excel.save();
        if (excelBytes != null) {
          await file.writeAsBytes(excelBytes);
          return true;
        }
        break;
      }
      
      return false;
    } catch (e) {
      print('Error updating inventory item: $e');
      return false;
    }
  }
  
  /// Update stock quantity for an inventory item
  Future<bool> updateInventoryItemStock(String itemId, double newStock) async {
    return await updateInventoryItemInExcel(itemId, {
      'currentStock': newStock,
    });
  }
  
  /// Add stock to an existing inventory item (additive operation)
  Future<bool> addInventoryItemStock(String itemId, double stockToAdd) async {
    try {
      // First, get the current item data to read existing stock
      final inventoryItems = await loadInventoryItemsFromExcel();
      final item = inventoryItems.firstWhere(
        (item) => item['id']?.toString() == itemId,
        orElse: () => {},
      );
      
      if (item.isEmpty) {
        print('Item not found: $itemId');
        return false;
      }
      
      // Get current stock and add the new amount
      final currentStock = (item['currentStock'] as num?)?.toDouble() ?? 0.0;
      final newTotalStock = currentStock + stockToAdd;
      
      print('Adding stock: Current=$currentStock, Adding=$stockToAdd, NewTotal=$newTotalStock');
      
      // Update with the new total
      return await updateInventoryItemInExcel(itemId, {
        'currentStock': newTotalStock,
      });
    } catch (e) {
      print('Error adding inventory item stock: $e');
      return false;
    }
  }
  
  /// Update an entire inventory item with new data
  Future<bool> updateInventoryItem(Map<String, dynamic> itemData) async {
    final itemId = itemData['id']?.toString();
    if (itemId == null || itemId.isEmpty) {
      return false;
    }
    
    return await updateInventoryItemInExcel(itemId, itemData);
  }
  
  /// Delete an inventory item (mark as inactive)
  Future<bool> deleteInventoryItem(String itemId) async {
    return await updateInventoryItemInExcel(itemId, {
      'status': 'Inactive',
    });
  }
  
  /// Get items with low stock (below minimum)
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final allItems = await loadInventoryItemsFromExcel();
    return allItems.where((item) {
      final currentStock = item['currentStock'] as double;
      final minimumStock = item['minimumStock'] as double;
      final status = item['status'] as String;
      return status == 'Active' && currentStock <= minimumStock;
    }).toList();
  }
  
  /// Create the inventory_items.xlsx file with proper structure for purchase entries
  Future<Excel> _createInventoryItemsFile(String filePath) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Items sheet (each row = one purchase entry)
    final Sheet itemsSheet = excel['Items'];
    
    // Add column headers for purchase-based tracking
    final headers = [
      'Item ID',
      'Name',
      'Category',
      'Description',
      'SKU',
      'Barcode',
      'Unit',
      'Quantity Purchased',  // Changed from 'Current Stock'
      'Minimum Stock',
      'Maximum Stock',
      'Cost Price',          // Changed from 'Unit Cost'
      'Selling Price',
      'Supplier',
      'Location',
      'Status',
      'Purchase Date',       // Changed from 'Date Added'
      'Last Updated',
      'Notes',
    ];
    
    // Add header styling
    for (var i = 0; i < headers.length; i++) {
      final cell = itemsSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: '#2E7D32',
        fontColorHex: '#FFFFFF',
      );
    }
    
    // Save the file
    final excelBytes = excel.save();
    if (excelBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);
    }
    
    return excel;
  }
  
  Future<void> saveOrderToExcel(Map<String, dynamic> order) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_orders_template.xlsx';
      final file = File(filePath);

      Excel excel;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        // Create the template if it doesn't exist using the existing method
        await generateOrderTemplate();
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      }

      final sheet = excel['Orders'];
      
      // Find the next empty row
      int nextRow = 1;
      while (nextRow < sheet.maxRows && sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: nextRow)).value != null) {
        nextRow++;
      }

      // Add order data to the row
      final orderValues = [
        order['orderId'] ?? '',
        order['customerName'] ?? '',
        order['customerId'] ?? '',
        order['orderDate'] ?? '',
        order['dueDate'] ?? '',
        order['items'] ?? '',
        order['totalAmount'] ?? 0.0,
        order['paidAmount'] ?? 0.0,
        order['status'] ?? 'Pending',
        order['priority'] ?? 'Normal',
        order['assignedTo'] ?? '',
        order['notes'] ?? '',
        order['paymentMethod'] ?? 'Cash',
      ];

      for (int i = 0; i < orderValues.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: nextRow));
        cell.value = orderValues[i];
      }

      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      }
    } catch (e) {
      print('Error saving order to Excel: $e');
      rethrow;
    }
  }
  
  Future<bool> saveOrderProfit(String orderId, double revenue, double cost, double profit, String customerName) async {
    print('saveOrderProfit: Not implemented yet');
    return false;
  }

  // ========== SALES TRACKING SYSTEM ==========
  
  /// Get the next Sale ID starting from 1001
  Future<int> getNextSaleId() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sales_records.xlsx');
      
      if (!file.existsSync()) {
        return 1001; // Starting sale ID
      }

      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      
      Sheet sheet;
      if (excel.tables.containsKey('Sales')) {
        sheet = excel['Sales'];
      } else if (excel.tables.containsKey('Sheet1')) {
        sheet = excel['Sheet1'];
      } else if (excel.tables.isNotEmpty) {
        sheet = excel[excel.tables.keys.first];
      } else {
        return 1001;
      }

      int maxSaleId = 1000; // Start from 1000 so next will be 1001
      
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isNotEmpty && row[0]?.value != null) {
          try {
            final saleId = int.parse(row[0]!.value.toString());
            if (saleId > maxSaleId) {
              maxSaleId = saleId;
            }
          } catch (e) {
            // Skip invalid sale IDs
          }
        }
      }
      
      return maxSaleId + 1;
    } catch (e) {
      print('Error getting next sale ID: $e');
      return 1001;
    }
  }

  /// Save individual sale details to sales Excel file with WAC-based profit calculation
  /// Calculates profit margin using WAC cost from inventory vs selling price from sale form
  Future<bool> saveSaleToExcel(Map<String, dynamic> saleData) async {
    try {
      print('🔍 DEBUG EXCEL: saveSaleToExcel called from: ${saleData['source'] ?? 'UNKNOWN'}');
      print('🔍 DEBUG EXCEL: saleData keys: ${saleData.keys}');
      print('🔍 DEBUG EXCEL: Complete saleData: $saleData');
      print('🔍 DEBUG EXCEL: VAT Amount from saleData: ${saleData['vatAmount']}');
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/sales_records.xlsx';
      final file = File(filePath);

      Excel excel;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = await _createSalesRecordsFile(filePath);
      }

      final sheet = excel['Sales'];
      
      // Process each item in the sale
      final items = saleData['items'] as List<Map<String, dynamic>>;
      
      // Extract VAT amount from saleData - ensure it's properly cast to double
      final vatAmountFromSale = (saleData['vatAmount'] as num?)?.toDouble() ?? 0.0;
      print('🔍 DEBUG: Extracted VAT amount as double: $vatAmountFromSale');
      
      for (final item in items) {
        final itemId = item['itemId']?.toString() ?? '';
        final itemName = item['itemName']?.toString() ?? '';
        final quantitySold = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
        final sellingPrice = double.tryParse(item['sellingPrice']?.toString() ?? '0') ?? 0.0;
        
        // Get WAC-based cost and update inventory using FIFO consumption
        final costResult = await _processFIFOCostAndUpdateStock(itemId, quantitySold);
        final wacCostPrice = costResult['costPrice'] ?? 0.0;
        final success = costResult['success'] ?? false;
        
        if (!success) {
          print('Warning: Could not process WAC-FIFO for item $itemId, using zero cost');
        }
        
        // Calculate selling price without VAT for Column J
        final vatAmountPerUnit = vatAmountFromSale / quantitySold; // VAT amount per unit
        final sellingPriceWithoutVAT = sellingPrice - vatAmountPerUnit; // Selling price minus VAT per unit
        final totalSellingPriceWithoutVAT = sellingPriceWithoutVAT * quantitySold; // Total selling price without VAT
        
        // NEW FORMULA: Calculate profit using: sale amount - VAT amount - unit cost
        final totalSaleAmount = quantitySold * sellingPrice; // Total sale amount (VAT-inclusive)
        final totalCostAmount = quantitySold * wacCostPrice; // Total unit cost
        final totalProfit = totalSaleAmount - vatAmountFromSale - totalCostAmount; // New profit formula
        final profitPerUnit = totalProfit / quantitySold; // Profit per unit
        
        // Calculate totals for other columns
        final totalCost = quantitySold * wacCostPrice;             // Total cost using WAC
        
        // Calculate profit margin percentage based on selling price without VAT
        final profitMarginPercent = sellingPriceWithoutVAT > 0 ? (profitPerUnit / sellingPriceWithoutVAT) * 100 : 0.0;
        
        // FIXED: Better row finding logic to prevent jumbled sheets
        int nextRow = 1; // Start from row 1 (after header row 0)
        
        // Find the actual next empty row
        for (int checkRow = 1; checkRow < 10000; checkRow++) { // Safety limit
          final checkCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: checkRow));
          if (checkCell.value == null || checkCell.value.toString().trim().isEmpty) {
            nextRow = checkRow;
            break;
          }
        }
        
        print('🔍 DEBUG: Adding sale data to row: $nextRow for item: $itemName');
        
        // FIXED: Validate sheet headers before adding data
        void validateSheetHeaders() {
          final expectedHeaders = [
            'Sale ID', 'Date', 'Customer Name', 'Item ID', 'Item Name', 
            'Quantity Sold', 'WAC Cost Price', 'Selling Price', 'VAT Amount', 
            'Selling Price (No VAT)', 'Total Cost', 'Total Sale', 
            'Profit Amount', 'Profit Margin %', 'Payment Status', 'Payment Method'
          ];
          
          try {
            for (int i = 0; i < expectedHeaders.length; i++) {
              final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
              final actualHeader = cell.value?.toString() ?? '';
              if (actualHeader != expectedHeaders[i]) {
                print('⚠️  WARNING: Header mismatch at column $i. Expected: "${expectedHeaders[i]}", Found: "$actualHeader"');
                // Fix the header
                cell.value = expectedHeaders[i];
              }
            }
          } catch (e) {
            print('❌ ERROR: Failed to validate headers: $e');
          }
        }
        
        validateSheetHeaders();
        
        // Add sale data to Excel with comprehensive profit analysis, customer information, and payment details
        final saleValues = [
          saleData['saleId'] ?? '',
          saleData['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          saleData['customerName'] ?? 'Walk-in Customer',      // Customer name from sale data
          itemId,
          itemName,
          quantitySold,
          wacCostPrice,                                          // WAC cost price (batch cost) - Column G (index 6)
          sellingPrice,                                          // Selling price (VAT-inclusive) - Column H (index 7)
          vatAmountFromSale,                                     // VAT Amount - Column I (index 8)
          totalSellingPriceWithoutVAT,                          // Selling price without VAT - Column J (index 9)
          totalCost,                                             // Total cost - Column K (index 10)
          totalSaleAmount,                                       // Total sale - Column L (index 11)
          totalProfit,                                           // Profit Amount - Column M (index 12)
          profitMarginPercent,                                   // Profit margin percentage - Column N (index 13)
          saleData['paymentStatus'] ?? 'Paid',                  // Payment Status - Column O (index 14)
          saleData['paymentMethod'] ?? '',                      // Payment Method - Column P (index 15)
        ];
        
        print('🔍 DEBUG: saleValues array: $saleValues');
        print('🔍 DEBUG: Column G (index 6) - WAC Cost Price: ${saleValues[6]}');
        print('🔍 DEBUG: Column H (index 7) - Selling Price (VAT-incl): ${saleValues[7]}');
        print('🔍 DEBUG: Column I (index 8) - VAT Amount: ${saleValues[8]}');
        print('🔍 DEBUG: Column J (index 9) - Selling Price (No VAT): ${saleValues[9]}');
        print('🔍 DEBUG: Column O (index 14) - Payment Status: ${saleValues[14]}');
        print('🔍 DEBUG: Column P (index 15) - Payment Method: ${saleValues[15]}');
        
        // FIXED: Validate data before writing to Excel
        bool validateSaleData() {
          if (saleValues.length != 16) {
            print('❌ ERROR: saleValues array length is ${saleValues.length}, expected 16');
            return false;
          }
          
          // Check for null or invalid numeric values
          for (int i = 5; i < saleValues.length; i++) { // Skip text fields (0-4)
            if (i == 5) continue; // Skip quantity (already validated)
            if (i == 14 || i == 15) continue; // Skip payment status and method (text fields)
            final value = saleValues[i];
            if (value is! num && (value is String && double.tryParse(value) == null)) {
              print('❌ ERROR: Invalid numeric value at index $i: $value');
              return false;
            }
          }
          
          print('✅ Data validation passed');
          return true;
        }
        
        if (!validateSaleData()) {
          print('❌ CRITICAL: Sale data validation failed, skipping Excel write');
          return false;
        }
        
        // FIXED: Safe cell value setting with proper error handling
        for (int i = 0; i < saleValues.length; i++) {
          try {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: nextRow));
            final value = saleValues[i];
            
            // Direct assignment with type conversion as needed
            if (value is num) {
              cell.value = value;
            } else if (value is String) {
              cell.value = value;
            } else {
              cell.value = value?.toString() ?? '';
            }
          } catch (e) {
            print('❌ ERROR: Failed to set cell value at column $i, row $nextRow: $e');
            // Fallback to basic assignment
            try {
              final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: nextRow));
              cell.value = saleValues[i];
            } catch (fallbackError) {
              print('❌ CRITICAL ERROR: Fallback assignment also failed: $fallbackError');
            }
          }
        }
        
        print('Sale recorded: ${itemName} | Qty: ${quantitySold} | Selling: BHD ${sellingPrice.toStringAsFixed(2)} (VAT-incl, Col H) | VAT: BHD ${vatAmountFromSale.toStringAsFixed(2)} (Col I) | Selling (No VAT): BHD ${totalSellingPriceWithoutVAT.toStringAsFixed(2)} (Col J) | WAC Cost: BHD ${wacCostPrice.toStringAsFixed(2)} (Col G) | Profit: BHD ${totalProfit.toStringAsFixed(2)} (Col M) | Payment: ${saleData['paymentStatus'] ?? 'Paid'} - ${saleData['paymentMethod'] ?? 'N/A'}');
        
        // Also save this sale as a transaction for revenue tracking
        await saveTransactionToExcel(
          transactionType: 'sale',
          partyName: saleData['customerName']?.toString().trim().isNotEmpty == true 
              ? saleData['customerName'] 
              : 'Walk-in Customer',
          amount: totalSaleAmount, // Positive amount for revenue
          description: 'Sale of ${quantitySold}x ${itemName}',
          reference: saleData['saleId']?.toString() ?? '',
          category: 'Sales Revenue',
          transactionDate: saleData['date'] != null 
              ? DateTime.tryParse(saleData['date'].toString()) ?? DateTime.now()
              : DateTime.now(),
          vatRate: 10.0, // 10% VAT rate
          vatAmount: vatAmountFromSale,
        );
      }
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        
        // Also save overall sale summary as a transaction if there are multiple items
        if (items.length > 1) {
          final totalSaleAmount = items.fold<double>(0.0, (sum, item) {
            final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
            final price = double.tryParse(item['sellingPrice']?.toString() ?? '0') ?? 0.0;
            return sum + (qty * price);
          });
          
          final itemsList = items.map((item) => item['itemName'] ?? 'Unknown Item').join(', ');
          
          await saveTransactionToExcel(
            transactionType: 'sale',
            partyName: saleData['customerName']?.toString().trim().isNotEmpty == true 
                ? saleData['customerName'] 
                : 'Walk-in Customer',
            amount: totalSaleAmount,
            description: 'Complete sale: $itemsList',
            reference: saleData['saleId']?.toString() ?? '',
            category: 'Sales Revenue',
            transactionDate: saleData['date'] != null 
                ? DateTime.tryParse(saleData['date'].toString()) ?? DateTime.now()
                : DateTime.now(),
            vatRate: 10.0, // 10% VAT rate
            vatAmount: saleData['vatAmount'] != null ? double.tryParse(saleData['vatAmount'].toString()) : null,
          );
        }
        
        // Also save to payment_received.xlsx
        await savePaymentReceivedToExcel(
          paymentDate: saleData['date'] != null 
              ? DateTime.tryParse(saleData['date'].toString()) ?? DateTime.now()
              : DateTime.now(),
          customerName: saleData['customerName']?.toString().trim().isNotEmpty == true 
              ? saleData['customerName'] 
              : 'Walk-in Customer',
          saleId: saleData['saleId']?.toString() ?? '',
          totalSellingPrice: items.fold<double>(0.0, (sum, item) {
            final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
            final price = double.tryParse(item['sellingPrice']?.toString() ?? '0') ?? 0.0;
            return sum + (qty * price);
          }),
          totalProfit: items.fold<double>(0.0, (sum, item) {
            final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
            final sellingPrice = double.tryParse(item['sellingPrice']?.toString() ?? '0') ?? 0.0;
            final costPrice = double.tryParse(item['wacCostPrice']?.toString() ?? '0') ?? 0.0;
            return sum + (qty * (sellingPrice - costPrice));
          }),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error saving sale to Excel: $e');
      return false;
    }
  }
  
  /// Create the sales_records.xlsx file with proper structure
  Future<Excel> _createSalesRecordsFile(String filePath) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Sales sheet
    final Sheet salesSheet = excel['Sales'];
    
    // Add column headers with profit margin analysis, customer information, and payment details
    final headers = [
      'Sale ID',
      'Date',
      'Customer Name',
      'Item ID',
      'Item Name',
      'Quantity Sold',
      'WAC Cost Price',       // Column G (index 6) - Batch Cost Price
      'Selling Price',        // Column H (index 7) - Selling Price (VAT-inclusive)
      'VAT Amount',           // Column I (index 8) - VAT Amount
      'Selling Price (No VAT)', // Column J (index 9) - Selling Price without VAT
      'Total Cost',           // Column K (index 10) - Total Cost
      'Total Sale',           // Column L (index 11) - Total Sale
      'Profit Amount',        // Column M (index 12) - Profit Amount
      'Profit Margin %',      // Column N (index 13) - Profit Margin %
      'Payment Status',       // Column O (index 14) - Payment Status (Paid/Credit)
      'Payment Method',       // Column P (index 15) - Payment Method (Cash/Card/Benefit/etc.)
    ];
    
    // Add header styling
    for (var i = 0; i < headers.length; i++) {
      final cell = salesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: '#1976D2',
        fontColorHex: '#FFFFFF',
      );
    }
    
    // Set column widths for better readability
    for (var i = 0; i < headers.length; i++) {
      salesSheet.setColWidth(i, 15.0);
    }
    
    // Save the file
    final excelBytes = excel.save();
    if (excelBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);
    }
    
    return excel;
  }
  
  /// Load all sales records from sales_records.xlsx for order management
  /// Returns sales data formatted for order display
  Future<List<Map<String, dynamic>>> loadSalesFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/sales_records.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Sales records file does not exist yet');
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Sales'];
      
      List<Map<String, dynamic>> salesOrders = [];
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        final saleId = row[0]?.value?.toString() ?? '';
        final saleDate = row[1]?.value?.toString() ?? '';
        final customerName = row[2]?.value?.toString() ?? 'Walk-in Customer';
        final itemName = row[4]?.value?.toString() ?? '';
        final quantitySold = double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0.0;
        final totalSale = double.tryParse(row[9]?.value?.toString() ?? '0') ?? 0.0;
        final profitAmount = double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0;
        
        // Format data for order display
        salesOrders.add({
          'orderId': saleId,
          'customerName': customerName,
          'items': itemName,
          'quantity': quantitySold,
          'totalCost': totalSale,
          'profit': profitAmount,
          'orderDate': saleDate,
          'status': 'completed', // Sales are always completed
          'paymentStatus': 'paid', // Sales are always paid
          'type': 'sale', // Mark as sale for distinction
        });
      }
      
      return salesOrders;
      
    } catch (e) {
      return [];
    }
  }

  /// Get grouped sales records by order ID for consolidated display
  /// Groups multiple items from the same order into a single record
  Future<List<Map<String, dynamic>>> getGroupedSalesFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/sales_records.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Sales records file does not exist yet');
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Sales'];
      
      Map<String, Map<String, dynamic>> groupedSales = {};
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        final saleId = row[0]?.value?.toString() ?? '';
        final saleDate = row[1]?.value?.toString() ?? '';
        final customerName = row[2]?.value?.toString() ?? 'Walk-in Customer';
        final itemName = row[4]?.value?.toString() ?? '';
        final quantitySold = double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0.0;
        final wacCostPrice = double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0;
        final vatAmount = double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0.0;
        final totalSaleAmount = double.tryParse(row[11]?.value?.toString() ?? '0') ?? 0.0;
        
        // Calculate profit using new formula: sale amount - VAT amount - unit cost
        final totalCostAmount = wacCostPrice * quantitySold;
        final recalculatedProfit = totalSaleAmount - vatAmount - totalCostAmount;
        
        if (groupedSales.containsKey(saleId)) {
          // Add to existing group
          final existingItems = List<Map<String, dynamic>>.from(groupedSales[saleId]!['itemsList']);
          existingItems.add({
            'itemName': itemName,
            'quantity': quantitySold,
            'totalSale': totalSaleAmount,
            'profit': recalculatedProfit,
          });
          
          groupedSales[saleId]!['itemsList'] = existingItems;
          groupedSales[saleId]!['totalCost'] = (groupedSales[saleId]!['totalCost'] as double) + totalSaleAmount;
          groupedSales[saleId]!['profit'] = (groupedSales[saleId]!['profit'] as double) + recalculatedProfit;
          groupedSales[saleId]!['quantity'] = (groupedSales[saleId]!['quantity'] as double) + quantitySold;
          groupedSales[saleId]!['itemCount'] = existingItems.length;
          
          // Update items display to show count
          if (existingItems.length == 1) {
            groupedSales[saleId]!['items'] = existingItems[0]['itemName'];
          } else {
            groupedSales[saleId]!['items'] = '${existingItems.length} items';
          }
        } else {
          // Create new group
          groupedSales[saleId] = {
            'orderId': saleId,
            'customerName': customerName,
            'items': itemName,
            'quantity': quantitySold,
            'totalCost': totalSaleAmount,
            'profit': recalculatedProfit,
            'orderDate': saleDate,
            'status': 'completed',
            'paymentStatus': 'paid',
            'type': 'sale',
            'itemCount': 1,
            'itemsList': [
              {
                'itemName': itemName,
                'quantity': quantitySold,
                'totalSale': totalSaleAmount,
                'profit': recalculatedProfit,
              }
            ],
          };
        }
      }
      
      final result = groupedSales.values.toList();
      return result;
      
    } catch (e) {
      return [];
    }
  }

  /// Get sales reports with profit margin analysis
  /// Returns detailed sales data with WAC-based profit calculations
  Future<List<Map<String, dynamic>>> getSalesReportsWithProfitAnalysis({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/sales_records.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Sales'];
      
      List<Map<String, dynamic>> salesReports = [];
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        final saleDate = row[1]?.value?.toString() ?? '';
        
        // Filter by date range if provided
        if (startDate != null || endDate != null) {
          try {
            final date = DateTime.parse(saleDate);
            if (startDate != null && date.isBefore(startDate)) continue;
            if (endDate != null && date.isAfter(endDate)) continue;
          } catch (e) {
            continue; // Skip invalid dates
          }
        }
        
        final sellingPrice = double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0;
        final wacCostPrice = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
        final totalSale = double.tryParse(row[9]?.value?.toString() ?? '0') ?? 0.0;
        final profitAmount = double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0;
        final profitMarginPercent = double.tryParse(row[11]?.value?.toString() ?? '0') ?? 0.0;
        
        salesReports.add({
          'saleId': row[0]?.value?.toString() ?? '',
          'date': saleDate,
          'customerName': row[2]?.value?.toString() ?? '',
          'itemId': row[3]?.value?.toString() ?? '',
          'itemName': row[4]?.value?.toString() ?? '',
          'quantitySold': double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0.0,
          'sellingPrice': sellingPrice,
          'wacCostPrice': wacCostPrice,
          'totalCost': double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0.0,
          'totalSale': totalSale,
          'profitAmount': profitAmount,
          'profitMarginPercent': profitMarginPercent,
          'grossMargin': sellingPrice > 0 ? ((sellingPrice - wacCostPrice) / sellingPrice) * 100 : 0.0,
        });
      }
      
      // Sort by date (newest first)
      salesReports.sort((a, b) => b['date'].compareTo(a['date']));
      
      return salesReports;
      
    } catch (e) {
      print('Error getting sales reports: $e');
      return [];
    }
  }
  
  /// Process WAC-based inventory consumption and update stock accordingly
  /// Uses FIFO for stock consumption but WAC-based cost pricing
  /// Returns detailed breakdown of cost calculation using inventory_items.xlsx
  Future<Map<String, dynamic>> _processFIFOCostAndUpdateStock(String itemId, double quantitySold) async {
    try {
      // Get all purchase entries for this item, sorted by purchase date (FIFO for consumption)
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Inventory file does not exist');
        return {'success': false, 'costPrice': 0.0, 'breakdown': []};
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      List<Map<String, dynamic>> itemBatches = [];
      
      // Load all entries for this itemId
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        if (row[0]?.value?.toString() == itemId) {
          final quantity = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
          if (quantity > 0) { // Only include rows with remaining stock
            itemBatches.add({
              'rowIndex': rowIndex,
              'itemId': row[0]?.value?.toString() ?? '',
              'name': row[1]?.value?.toString() ?? '',
              'quantity': quantity,
              'costPrice': double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0, // WAC-based cost
              'purchaseDate': (row.length > 15 ? row[15]?.value?.toString() : '') ?? '',
            });
          }
        }
      }
      
      if (itemBatches.isEmpty) {
        print('No inventory batches found for item $itemId');
        return {'success': false, 'costPrice': 0.0, 'breakdown': []};
      }
      
      // Sort by purchase date (FIFO for consumption - oldest first)
      itemBatches.sort((a, b) => a['purchaseDate'].compareTo(b['purchaseDate']));
      
      double remainingToSell = quantitySold;
      double totalCost = 0.0;
      double weightedAverageCost = 0.0;
      List<Map<String, dynamic>> breakdown = [];
      
      print('WAC-FIFO Processing for Item $itemId - Selling $quantitySold units:');
      
      // Process batches in FIFO order (oldest consumption first) with WAC pricing
      for (final batch in itemBatches) {
        if (remainingToSell <= 0) break;
        
        final batchQtyAvailable = batch['quantity'];
        final batchCostPrice = batch['costPrice']; // This is now WAC-based cost
        
        final qtyToTakeFromThisBatch = remainingToSell > batchQtyAvailable 
            ? batchQtyAvailable 
            : remainingToSell;
        
        // Add to total cost calculation using WAC-based cost
        final batchCost = qtyToTakeFromThisBatch * batchCostPrice;
        totalCost += batchCost;
        
        // Add to breakdown for transparency
        breakdown.add({
          'rowIndex': batch['rowIndex'],
          'purchaseDate': batch['purchaseDate'],
          'qtyUsed': qtyToTakeFromThisBatch,
          'costPrice': batchCostPrice,
          'totalCost': batchCost,
          'qtyBefore': batchQtyAvailable,
          'qtyAfter': batchQtyAvailable - qtyToTakeFromThisBatch,
        });
        
        print('  - From Purchase ${batch['purchaseDate']}: ${qtyToTakeFromThisBatch} units @ BHD ${batchCostPrice} (WAC) = BHD ${batchCost.toStringAsFixed(2)}');
        
        // Update or delete the row in Excel
        final newQty = batchQtyAvailable - qtyToTakeFromThisBatch;
        if (newQty <= 0) {
          // Delete the entire row if depleted
          sheet.removeRow(batch['rowIndex']);
          print('    Batch depleted - row deleted');
        } else {
          // Update the quantity in the row
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: batch['rowIndex']));
          cell.value = newQty;
          print('    Updated quantity to ${newQty}');
        }
        
        remainingToSell -= qtyToTakeFromThisBatch;
      }
      
      // Save the updated Excel file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      }
      
      // Calculate weighted average cost price for this sale
      weightedAverageCost = quantitySold > 0 ? totalCost / quantitySold : 0.0;
      
      print('  WAC-FIFO Summary: Total Cost = BHD ${totalCost.toStringAsFixed(2)}, Weighted Avg Cost = BHD ${weightedAverageCost.toStringAsFixed(2)}');
      
      if (remainingToSell > 0) {
        print('Warning: Insufficient stock for item $itemId. Could not fulfill ${remainingToSell} units');
      }
      
      return {
        'success': true,
        'costPrice': weightedAverageCost,
        'totalCost': totalCost,
        'breakdown': breakdown,
        'insufficientStock': remainingToSell,
      };
      
    } catch (e) {
      print('Error processing FIFO for item $itemId: $e');
      return {'success': false, 'costPrice': 0.0, 'breakdown': []};
    }
  }

  // ========== INVENTORY BATCH MANAGEMENT ==========
  
  /// Get WAC-based cost analysis for a potential sale without actually processing it
  /// Uses FIFO for consumption order but WAC-based cost pricing
  /// Useful for previewing what the cost would be before making a sale
  Future<Map<String, dynamic>> getFIFOCostAnalysis(String itemId, double quantityToSell) async {
    try {
      // Get all purchase entries for this item from inventory_items.xlsx
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        return {
          'canFulfill': false,
          'totalCost': 0.0,
          'weightedAverageCost': 0.0,
          'breakdown': [],
          'message': 'Inventory file does not exist'
        };
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      List<Map<String, dynamic>> itemBatches = [];
      
      // Load all entries for this itemId with remaining stock
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        if (row[0]?.value?.toString() == itemId) {
          final quantity = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
          if (quantity > 0) {
            itemBatches.add({
              'purchaseDate': (row.length > 15 ? row[15]?.value?.toString() : '') ?? '',
              'availableQty': quantity,
              'costPrice': double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0,
              'supplier': (row.length > 12 ? row[12]?.value?.toString() : '') ?? '',
            });
          }
        }
      }
      
      if (itemBatches.isEmpty) {
        return {
          'canFulfill': false,
          'totalCost': 0.0,
          'weightedAverageCost': 0.0,
          'breakdown': [],
          'message': 'No inventory entries found for this item'
        };
      }
      
      // Sort by purchase date (FIFO - oldest first)
      itemBatches.sort((a, b) => a['purchaseDate'].compareTo(b['purchaseDate']));
      
      double remainingToSell = quantityToSell;
      double totalCost = 0.0;
      List<Map<String, dynamic>> breakdown = [];
      
      for (final batch in itemBatches) {
        if (remainingToSell <= 0) break;
        
        final batchQtyAvailable = batch['availableQty'];
        final batchCostPrice = batch['costPrice'];
        
        final qtyToTakeFromThisBatch = remainingToSell > batchQtyAvailable 
            ? batchQtyAvailable 
            : remainingToSell;
        
        final batchCost = qtyToTakeFromThisBatch * batchCostPrice;
        totalCost += batchCost;
        
        breakdown.add({
          'purchaseDate': batch['purchaseDate'],
          'availableQty': batchQtyAvailable,
          'qtyToUse': qtyToTakeFromThisBatch,
          'costPrice': batchCostPrice,
          'batchCost': batchCost,
          'supplier': batch['supplier'],
        });
        
        remainingToSell -= qtyToTakeFromThisBatch;
      }
      
      final weightedAverageCost = quantityToSell > 0 ? totalCost / quantityToSell : 0.0;
      final canFulfill = remainingToSell <= 0;
      
      return {
        'canFulfill': canFulfill,
        'totalCost': totalCost,
        'weightedAverageCost': weightedAverageCost,
        'breakdown': breakdown,
        'insufficientQty': remainingToSell > 0 ? remainingToSell : 0.0,
        'message': canFulfill 
            ? 'Sale can be fulfilled using FIFO method'
            : 'Insufficient stock - missing ${remainingToSell.toStringAsFixed(2)} units'
      };
      
    } catch (e) {
      return {
        'canFulfill': false,
        'totalCost': 0.0,
        'weightedAverageCost': 0.0,
        'breakdown': [],
      };
    }
  }
  
  /// Get current Weighted Average Cost (WAC) and total stock for an item
  /// Returns the WAC and total available quantity for the specified item
  Future<Map<String, dynamic>> getCurrentWACForItem(String itemId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        return {
          'success': false,
          'wac': 0.0,
          'totalQuantity': 0.0,
          'totalValue': 0.0,
          'message': 'Inventory file does not exist'
        };
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      double totalQuantity = 0.0;
      double totalValue = 0.0;
      int entriesFound = 0;
      
      // Load all entries for this itemId with remaining stock
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        if (row[0]?.value?.toString() == itemId) {
          final quantity = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
          final costPrice = double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0;
          
          if (quantity > 0) {
            totalQuantity += quantity;
            totalValue += (quantity * costPrice);
            entriesFound++;
          }
        }
      }
      
      if (entriesFound == 0) {
        return {
          'success': false,
          'wac': 0.0,
          'totalQuantity': 0.0,
          'totalValue': 0.0,
          'message': 'No stock found for item $itemId'
        };
      }
      
      final wac = totalQuantity > 0 ? totalValue / totalQuantity : 0.0;
      
      return {
        'success': true,
        'wac': wac,
        'totalQuantity': totalQuantity,
        'totalValue': totalValue,
        'entriesCount': entriesFound,
        'message': 'WAC calculated successfully'
      };
      
    } catch (e) {
      return {
        'success': false,
        'wac': 0.0,
        'totalQuantity': 0.0,
        'totalValue': 0.0,
      };
    }
  }
  
  /// Get WAC summary for all items in inventory
  /// Returns a list of all items with their current WAC, quantities, and values
  Future<List<Map<String, dynamic>>> getWACSummaryForAllItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      Map<String, Map<String, dynamic>> itemsData = {};
      
      // Aggregate data by item ID
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        final itemId = row[0]?.value?.toString() ?? '';
        final itemName = row[1]?.value?.toString() ?? '';
        final category = row[2]?.value?.toString() ?? '';
        final sku = row[4]?.value?.toString() ?? '';
        final unit = row[6]?.value?.toString() ?? 'pcs';
        final quantity = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
        final costPrice = double.tryParse(row[10]?.value?.toString() ?? '0') ?? 0.0;
        final sellingPrice = double.tryParse(row[11]?.value?.toString() ?? '0') ?? 0.0;
        
        if (quantity > 0 && itemId.isNotEmpty) {
          if (!itemsData.containsKey(itemId)) {
            itemsData[itemId] = {
              'itemId': itemId,
              'name': itemName,
              'category': category,
              'sku': sku,
              'unit': unit,
              'totalQuantity': 0.0,
              'totalValue': 0.0,
              'entries': 0,
              'sellingPrice': sellingPrice,
            };
          }
          
          itemsData[itemId]!['totalQuantity'] = 
              (itemsData[itemId]!['totalQuantity'] as double) + quantity;
          itemsData[itemId]!['totalValue'] = 
              (itemsData[itemId]!['totalValue'] as double) + (quantity * costPrice);
          itemsData[itemId]!['entries'] = 
              (itemsData[itemId]!['entries'] as int) + 1;
        }
      }
      
      // Calculate WAC for each item
      List<Map<String, dynamic>> wacSummary = [];
      for (var itemData in itemsData.values) {
        final totalQty = itemData['totalQuantity'] as double;
        final totalValue = itemData['totalValue'] as double;
        final wac = totalQty > 0 ? totalValue / totalQty : 0.0;
        final sellingPrice = itemData['sellingPrice'] as double;
        final grossMargin = sellingPrice > 0 ? ((sellingPrice - wac) / sellingPrice) * 100 : 0.0;
        
        wacSummary.add({
          'itemId': itemData['itemId'],
          'name': itemData['name'],
          'category': itemData['category'],
          'sku': itemData['sku'],
          'unit': itemData['unit'],
          'totalQuantity': totalQty,
          'wac': wac,
          'totalValue': totalValue,
          'entries': itemData['entries'],
          'sellingPrice': sellingPrice,
          'grossMarginPercent': grossMargin,
        });
      }
      
      // Sort by item name
      wacSummary.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      
      return wacSummary;
      
    } catch (e) {
      print('Error getting WAC summary: $e');
      return [];
    }
  }
  

  

  

  

  

  

  
  Future<bool> updateMaterialStock(String materialId, double quantity) async {
    try {
      // First, get the current material data to read existing stock
      final materials = await loadMaterialStockFromExcel();
      final material = materials.firstWhere(
        (mat) => mat['id']?.toString() == materialId,
        orElse: () => {},
      );
      
      if (material.isEmpty) {
        print('Material not found: $materialId');
        return false;
      }
      
      // Get current stock and subtract the used quantity
      final currentStock = (material['currentStock'] as num?)?.toDouble() ?? 0.0;
      final newStock = currentStock - quantity; // Subtract because materials are being consumed
      
      print('Updating material stock: Current=$currentStock, Used=$quantity, NewStock=$newStock');
      
      // Prevent negative stock (optional - you might want to allow this for tracking)
      if (newStock < 0) {
        print('Warning: Material $materialId will have negative stock: $newStock');
      }
      
      // Update the material stock in the materials sheet
      return await updateMaterialStockInExcel(materialId, newStock);
    } catch (e) {
      print('Error updating material stock: $e');
      return false;
    }
  }
  
  /// Helper method to update material stock in Excel
  Future<bool> updateMaterialStockInExcel(String materialId, double newStock) async {
    try {
      // This method should update the material stock in the Excel file
      // For now, we'll use the existing updateInventoryItemInExcel method
      // if materials are stored in the same sheet, otherwise we need a separate implementation
      
      // Check if we have a separate materials sheet implementation
      // For now, let's assume materials are in the inventory sheet
      return await updateInventoryItemInExcel(materialId, {
        'currentStock': newStock,
      });
    } catch (e) {
      print('Error updating material stock in Excel: $e');
      return false;
    }
  }
  
  Future<void> calculateAndSaveTodaysProfit() async {
    print('calculateAndSaveTodaysProfit: Not implemented yet');
  }
  
  Future<Map<String, dynamic>> calculateVatSummary({DateTime? startDate, DateTime? endDate}) async {
    print('calculateVatSummary: Not implemented yet');
    return {};
  }
  
  Future<List<Map<String, dynamic>>> loadVatTransactions({DateTime? startDate, DateTime? endDate, String? type}) async {
    print('loadVatTransactions: Not implemented yet');
    return [];
  }
  
  Future<String> exportVatReportToExcel({DateTime? startDate, DateTime? endDate, String? filename}) async {
    // TODO: Implement VAT report export - use inventory_vat_report_[timestamp].xlsx naming
    print('exportVatReportToExcel: Not implemented yet');
    return '';
  }
  
  // Missing getters for test file
  Future<List<Map<String, dynamic>>> get loadOrderProfits async {
    print('loadOrderProfits: Not implemented yet');
    return [];
  }
  
  Future<bool> get saveDailyProfit async {
    print('saveDailyProfit: Not implemented yet');
    return false;
  }
  
  Future<List<double>> get loadDailyProfits async {
    print('loadDailyProfits: Not implemented yet');
    return [];
  }
  
  Future<bool> addVendorToExcel(Map<String, dynamic> vendor) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_vendors.xlsx';
      
      Excel excel;
      final file = File(filePath);
      
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = await _createVendorsFile(filePath);
      }
      
      final sheet = excel['Vendors'];
      
      // Generate vendor ID if not provided
      String vendorId = vendor['vendorId']?.toString() ?? '';
      if (vendorId.isEmpty) {
        vendorId = 'VEN${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Check for duplicates based on vendor name
      bool isDuplicate = false;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row.length >= 2) {
          final existingName = (row[1]?.value?.toString() ?? '').toLowerCase();
          final newName = (vendor['vendorName']?.toString() ?? '').toLowerCase();
          
          if (existingName == newName && existingName.isNotEmpty) {
            isDuplicate = true;
            break;
          }
        }
      }
      
      if (isDuplicate) {
        print('Duplicate vendor found, skipping add');
        return false;
      }
      
      // Find the next empty row
      int nextRow = sheet.maxRows;
      
      // Add the vendor data
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: nextRow)).value = vendorId;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: nextRow)).value = vendor['vendorName']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: nextRow)).value = vendor['email']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: nextRow)).value = vendor['phone']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: nextRow)).value = vendor['address']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: nextRow)).value = vendor['city']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: nextRow)).value = vendor['country']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: nextRow)).value = vendor['vatNumber']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: nextRow)).value = vendor['maximumCredit']?.toString() ?? '0.0';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: nextRow)).value = vendor['currentCredit']?.toString() ?? '0.0';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: nextRow)).value = vendor['notes']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: nextRow)).value = vendor['status']?.toString() ?? 'Active';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: nextRow)).value = DateFormat('dd/MM/yyyy').format(DateTime.now());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: nextRow)).value = vendor['totalPurchases']?.toString() ?? '0.000';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: nextRow)).value = vendor['lastPurchaseDate']?.toString() ?? '';
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print('Vendor added successfully: $vendorId - ${vendor['vendorName']}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error adding vendor to Excel: $e');
      return false;
    }
  }
  
  Future<bool> updateVendorInExcel(Map<String, dynamic> vendor) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_vendors.xlsx';
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('Vendors file does not exist');
        return false;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Vendors'];
      
      final vendorId = vendor['vendorId']?.toString() ?? '';
      if (vendorId.isEmpty) {
        print('Vendor ID is required for update');
        return false;
      }
      
      // Find the vendor by ID
      int targetRow = -1;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row.length >= 1) {
          final existingId = row[0]?.value?.toString() ?? '';
          if (existingId == vendorId) {
            targetRow = rowIndex;
            break;
          }
        }
      }
      
      if (targetRow == -1) {
        print('Vendor not found: $vendorId');
        return false;
      }
      
      // Update the vendor data
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: targetRow)).value = vendor['vendorName']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: targetRow)).value = vendor['email']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: targetRow)).value = vendor['phone']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: targetRow)).value = vendor['address']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: targetRow)).value = vendor['city']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: targetRow)).value = vendor['country']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: targetRow)).value = vendor['vatNumber']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: targetRow)).value = vendor['maximumCredit']?.toString() ?? '0.0';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: targetRow)).value = vendor['currentCredit']?.toString() ?? '0.0';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: targetRow)).value = vendor['notes']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: targetRow)).value = vendor['status']?.toString() ?? 'Active';
      // Don't update date added, total purchases, or last purchase date in general updates
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print('Vendor updated successfully: $vendorId - ${vendor['vendorName']}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating vendor in Excel: $e');
      return false;
    }
  }
  
  Future<bool> deleteVendorFromExcel(String vendorId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_vendors.xlsx';
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('Vendors file does not exist');
        return false;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Vendors'];
      
      if (vendorId.isEmpty) {
        print('Vendor ID is required for deletion');
        return false;
      }
      
      // Find the vendor by ID
      int targetRow = -1;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row.length >= 1) {
          final existingId = row[0]?.value?.toString() ?? '';
          if (existingId == vendorId) {
            targetRow = rowIndex;
            break;
          }
        }
      }
      
      if (targetRow == -1) {
        print('Vendor not found: $vendorId');
        return false;
      }
      
      // Instead of actually deleting, mark as inactive
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: targetRow)).value = 'Inactive';
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print('Vendor marked as inactive: $vendorId');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting vendor from Excel: $e');
      return false;
    }
  }

  /// Update vendor purchase totals and last purchase date
  Future<bool> updateVendorPurchaseStats(String vendorName, double purchaseAmount) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_vendors.xlsx';
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('Vendors file does not exist');
        return false;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Vendors'];
      
      // Find the vendor by name
      int targetRow = -1;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row.length >= 2) {
          final existingName = (row[1]?.value?.toString() ?? '').toLowerCase();
          if (existingName == vendorName.toLowerCase()) {
            targetRow = rowIndex;
            break;
          }
        }
      }
      
      if (targetRow == -1) {
        print('Vendor not found for purchase update: $vendorName');
        return false;
      }
      
      // Get current total purchases
      double currentTotal = 0.0;
      final currentTotalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: targetRow));
      if (currentTotalCell.value != null) {
        currentTotal = double.tryParse(currentTotalCell.value.toString()) ?? 0.0;
      }
      
      // Update total purchases
      final newTotal = currentTotal + purchaseAmount;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: targetRow)).value = newTotal.toStringAsFixed(3);
      
      // Update last purchase date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: targetRow)).value = DateFormat('dd/MM/yyyy').format(DateTime.now());
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print('Vendor purchase stats updated: $vendorName - Total: ${newTotal.toStringAsFixed(3)} BHD');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating vendor purchase stats: $e');
      return false;
    }
  }

  /// Update vendor credit amount in vendor Excel file
  /// operation: 'add' to increase credit, 'subtract' to decrease credit
  Future<bool> updateVendorCredit(String vendorName, double creditAmount, String operation) async {
    try {
      print('🔍 updateVendorCredit called with: vendor=$vendorName, amount=$creditAmount, operation=$operation');
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_vendors.xlsx';
      print('🔍 Vendors file path: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Vendors file does not exist at: $filePath');
        return false;
      }

      print('✅ Vendors file found, loading...');
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Vendors'];
      
      print('📊 Vendors sheet loaded, searching for vendor: $vendorName');
      
      // Find the vendor by name
      int targetRow = -1;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row.length >= 2) {
          final existingName = (row[1]?.value?.toString() ?? '').toLowerCase();
          print('🔍 Checking row $rowIndex: "${row[1]?.value?.toString()}" vs "$vendorName"');
          if (existingName == vendorName.toLowerCase()) {
            targetRow = rowIndex;
            print('✅ Found vendor at row: $targetRow');
            break;
          }
        }
      }
      
      if (targetRow == -1) {
        print('❌ Vendor not found for credit update: $vendorName');
        return false;
      }
      
      // Get current credit amount (column 9 - currentCredit)
      double currentCredit = 0.0;
      final currentCreditCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: targetRow));
      if (currentCreditCell.value != null) {
        currentCredit = double.tryParse(currentCreditCell.value.toString()) ?? 0.0;
      }
      
      print('💰 Current credit for $vendorName: ${currentCredit.toStringAsFixed(3)} BHD');
      
      // Calculate new credit based on operation
      double newCredit = currentCredit;
      if (operation == 'add') {
        newCredit = currentCredit + creditAmount;
        print('💳 Adding credit: $vendorName - $creditAmount BHD (${currentCredit.toStringAsFixed(3)} → ${newCredit.toStringAsFixed(3)})');
      } else if (operation == 'subtract') {
        newCredit = currentCredit - creditAmount;
        print('💳 Reducing credit: $vendorName - $creditAmount BHD (${currentCredit.toStringAsFixed(3)} → ${newCredit.toStringAsFixed(3)})');
      } else {
        print('❌ Invalid operation for vendor credit update: $operation');
        return false;
      }
      
      // Ensure credit doesn't go below zero
      if (newCredit < 0) {
        newCredit = 0.0;
        print('⚠️ Credit adjusted to zero (cannot be negative)');
      }
      
      // Update the credit cell
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: targetRow)).value = 
          newCredit.toStringAsFixed(3);
      
      print('💾 Saving updated vendor file...');
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print('✅ Vendor credit updated: $vendorName - New credit: ${newCredit.toStringAsFixed(3)} BHD');
        return true;
      } else {
        print('❌ Failed to save vendor file');
        return false;
      }
    } catch (e) {
      print('❌ Error updating vendor credit: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Process vendor credit payment - reduces vendor's credit amount
  /// This should be called when a payment is made to a vendor to reduce their credit
  Future<bool> processVendorCreditPayment(String vendorName, double paymentAmount) async {
    try {
      print('💰 Processing vendor credit payment: $vendorName - Payment: ${paymentAmount.toStringAsFixed(3)} BHD');
      
      // Reduce vendor credit
      final creditUpdateSuccess = await updateVendorCredit(vendorName, paymentAmount, 'subtract');
      
      if (creditUpdateSuccess) {
        // Log this as a transaction (money going out for vendor payment)
        final transactionSuccess = await saveTransactionToExcel(
          transactionType: 'vendor_payment',
          partyName: vendorName,
          amount: -paymentAmount, // Negative because money is going out
          description: 'Payment to vendor: $vendorName',
          category: 'Vendor Payment',
          transactionDate: DateTime.now(),
          vatRate: null, // No VAT for vendor payments
          vatAmount: null,
        );
        
        if (transactionSuccess) {
          print('✅ Vendor credit payment processed successfully: $vendorName');
        } else {
          print('⚠️ Credit updated but failed to log transaction for vendor payment: $vendorName');
        }
        
        return true;
      } else {
        print('❌ Failed to update vendor credit for payment: $vendorName');
        return false;
      }
    } catch (e) {
      print('❌ Error processing vendor credit payment: $e');
      return false;
    }
  }
  
  Future<bool> deleteMaterial(String materialId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Inventory file does not exist');
        return false;
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      // Find and delete the material row
      bool found = false;
      for (int rowIndex = sheet.maxRows - 1; rowIndex >= 1; rowIndex--) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row[0]?.value?.toString() == materialId) {
          sheet.removeRow(rowIndex);
          found = true;
          break;
        }
      }
      
      if (!found) {
        print('Material with ID $materialId not found');
        return false;
      }
      
      // Save the file
      final newBytes = excel.encode();
      if (newBytes != null) {
        await file.writeAsBytes(newBytes);
        print('Successfully deleted material with ID: $materialId');
        return true;
      } else {
        print('Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('Error deleting material: $e');
      return false;
    }
  }
  
  Future<bool> addMaterialStock(String materialId, double quantity, double purchaseCost, double sellingPrice) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Inventory file does not exist');
        return false;
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      // Find and update the material
      bool found = false;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row[0]?.value?.toString() == materialId) {
          // Update stock and costs
          final currentStock = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0.0;
          final newStock = currentStock + quantity;
          
          // Column H: Current Stock (quantity)
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = newStock;
          // Column K: Cost Price
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = purchaseCost;
          // Column L: Selling Price  
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex)).value = sellingPrice;
          // Column Q: Last Updated
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex)).value = DateTime.now().toIso8601String();
          
          found = true;
          break;
        }
      }
      
      if (!found) {
        print('Material with ID $materialId not found');
        return false;
      }
      
      // Save the file
      final newBytes = excel.encode();
      if (newBytes != null) {
        await file.writeAsBytes(newBytes);
        print('Successfully updated material stock for ID: $materialId');
        return true;
      } else {
        print('Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('Error adding material stock: $e');
      return false;
    }
  }
  
  Future<bool> addMaterial(Map<String, dynamic> material) async {
    // TODO: Implement material addition - save to inventory_materials_stock.xlsx
    print('addMaterial: Not implemented yet');
    return false;
  }
  
  Future<bool> updateMaterial(Map<String, dynamic> material) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Inventory file does not exist');
        return false;
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Items'];
      
      // Find and update the material
      bool found = false;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row[0]?.value?.toString() == material['id']) {
          // Update all material fields
          // Column B: Name
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = material['name'];
          // Column C: Category
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = material['category'];
          // Column G: Unit
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = material['unit'];
          // Column H: Current Stock
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = material['currentStock'];
          // Column I: Minimum Stock
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = material['minimumStock'];
          // Column K: Cost Price (purchaseCost maps to costPrice in Excel)
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = material['purchaseCost'];
          // Column L: Selling Price
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex)).value = material['sellingPrice'];
          // Column M: Supplier
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex)).value = material['supplier'];
          // Column Q: Last Updated
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex)).value = DateTime.now().toIso8601String();
          // Column R: Notes
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex)).value = material['notes'];
          
          found = true;
          break;
        }
      }
      
      if (!found) {
        print('Material with ID ${material['id']} not found');
        return false;
      }
      
      // Save the file
      final newBytes = excel.encode();
      if (newBytes != null) {
        await file.writeAsBytes(newBytes);
        print('Successfully updated material: ${material['name']}');
        return true;
      } else {
        print('Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('Error updating material: $e');
      return false;
    }
  }
  

  Future<bool> deleteCustomer(String customerId) async {
    print('deleteCustomer: Not implemented yet');
    return false;
  }
  
  Future<bool> addCustomerToExcelWithId(Map<String, dynamic> customer) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_customer_list.xlsx';
      final file = File(filePath);
      
      Excel excel;
      
      // Check if file exists, if not create it
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        // Create new Excel file with headers
        excel = Excel.createExcel();
        excel.delete('Sheet1'); // Remove default sheet
        excel['customer_list']; // Create customer_list sheet
        
        // Add headers
        final sheet = excel['customer_list'];
        _setCellValue(sheet, 0, 0, 'ID');
        _setCellValue(sheet, 1, 0, 'Name');
        _setCellValue(sheet, 2, 0, 'Phone');
        _setCellValue(sheet, 3, 0, 'Email');
        _setCellValue(sheet, 4, 0, 'Address');
        _setCellValue(sheet, 5, 0, 'Notes');
      }
      
      final sheet = excel['customer_list'];
      
      // Find the next empty row
      int nextRow = sheet.maxRows;
      
      // Add customer data to the new row
      _setCellValue(sheet, 0, nextRow, customer['id']?.toString() ?? '');
      _setCellValue(sheet, 1, nextRow, customer['name']?.toString() ?? '');
      _setCellValue(sheet, 2, nextRow, customer['phone']?.toString() ?? '');
      _setCellValue(sheet, 3, nextRow, customer['email']?.toString() ?? '');
      _setCellValue(sheet, 4, nextRow, customer['address']?.toString() ?? '');
      _setCellValue(sheet, 5, nextRow, customer['notes']?.toString() ?? '');
      
      // Save the Excel file
      final newBytes = excel.encode();
      if (newBytes != null) {
        await file.writeAsBytes(newBytes);
        print('Customer added successfully to Excel file');
        return true;
      } else {
        print('Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('Error adding customer to Excel: $e');
      return false;
    }
  }

  // ========== TRANSACTION MANAGEMENT SYSTEM ==========
  
  /// Save a transaction to the transaction_details.xlsx file
  /// amount: positive for income (sales, payments received), negative for expenses (payments made, salaries, etc.)
  Future<bool> saveTransactionToExcel({
    required String transactionType, // 'income', 'expense', 'sale', 'purchase', 'salary', 'supplier_payment', etc.
    required String partyName, // Customer name, Vendor name, Employee name, etc.
    required double amount, // Positive for income, Negative for expenses
    required String description,
    String? reference, // Sale ID, Invoice ID, etc.
    String? category, // 'Sales', 'Inventory Purchase', 'Salary', 'Rent', 'Utilities', etc.
    DateTime? transactionDate,
    double? vatRate, // VAT rate percentage (e.g., 10.0 for 10%)
    double? vatAmount, // Calculated VAT amount
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/transaction_details.xlsx';
      
      Excel excel;
      final file = File(filePath);
      
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = await _createTransactionDetailsFile(filePath);
      }
      
      final sheet = excel['Transaction Details'];
      
      // Generate transaction ID
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
      final date = transactionDate ?? DateTime.now();
      
      // Find next empty row
      int nextRow = 1;
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          nextRow = i;
          break;
        }
        nextRow = i + 1;
      }
      
      // Add transaction data
      _setCellValue(sheet, 0, nextRow, transactionId); // Transaction ID
      _setCellValue(sheet, 1, nextRow, DateFormat('dd/MM/yyyy HH:mm').format(date)); // Date & Time
      _setCellValue(sheet, 2, nextRow, transactionType); // Transaction Type
      _setCellValue(sheet, 3, nextRow, partyName); // Party Name (Customer/Vendor/Employee)
      _setCellValue(sheet, 4, nextRow, amount.toString()); // Amount (+ for income, - for expense)
      _setCellValue(sheet, 5, nextRow, vatRate?.toString() ?? ''); // VAT Rate
      _setCellValue(sheet, 6, nextRow, vatAmount?.toString() ?? ''); // VAT Amount
      _setCellValue(sheet, 7, nextRow, description); // Description
      _setCellValue(sheet, 8, nextRow, reference ?? ''); // Reference (Sale ID, Invoice ID, etc.)
      _setCellValue(sheet, 9, nextRow, category ?? transactionType); // Category
      _setCellValue(sheet, 10, nextRow, amount > 0 ? 'Income' : 'Expense'); // Flow Type
      
      // Save the file
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error saving transaction to Excel: $e');
      return false;
    }
  }
  
  /// Load all transactions from transaction_details.xlsx
  Future<List<Map<String, dynamic>>> loadTransactionsFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/transaction_details.xlsx';
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('Transaction details file does not exist: $filePath');
        return [];
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final sheet = excel['Transaction Details'];

      final List<Map<String, dynamic>> transactionsList = [];
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        
        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
        
        try {
          final transaction = {
            'transactionId': row[0]?.value?.toString() ?? '',
            'date': _parseDateValue(row, {'Date': 1}, 'Date') ?? DateTime.now(),
            'transactionType': row[2]?.value?.toString() ?? '',
            'partyName': row[3]?.value?.toString() ?? '',
            'amount': _parseDoubleValue(row, {'Amount': 4}, 'Amount') ?? 0.0,
            'vatRate': _parseDoubleValue(row, {'VAT': 5}, 'VAT') ?? 0.0,
            'vatAmount': _parseDoubleValue(row, {'VAT Amount': 6}, 'VAT Amount') ?? 0.0,
            'description': row[7]?.value?.toString() ?? '',
            'reference': row[8]?.value?.toString() ?? '',
            'category': row[9]?.value?.toString() ?? '',
            'flowType': row[10]?.value?.toString() ?? '',
          };
          
          transactionsList.add(transaction);
        } catch (e) {
          print('Error parsing transaction row $rowIndex: $e');
        }
      }
      
      print('Loaded ${transactionsList.length} transactions');
      return transactionsList;
      
    } catch (e) {
      print('Error loading transactions from Excel: $e');
      return [];
    }
  }
  
  /// Get total profit by summing all transaction amounts
  Future<double> getTotalProfit() async {
    try {
      final transactions = await loadTransactionsFromExcel();
      double totalProfit = 0.0;
      
      for (final transaction in transactions) {
        final amount = transaction['amount'] as double? ?? 0.0;
        totalProfit += amount;
      }
      
      return totalProfit;
    } catch (e) {
      print('Error calculating total profit: $e');
      return 0.0;
    }
  }
  
  /// Get profit for a specific date range
  Future<double> getProfitForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await loadTransactionsFromExcel();
      double profit = 0.0;
      
      for (final transaction in transactions) {
        final date = transaction['date'] as DateTime;
        if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
            date.isBefore(endDate.add(const Duration(days: 1)))) {
          final amount = transaction['amount'] as double? ?? 0.0;
          profit += amount;
        }
      }
      
      return profit;
    } catch (e) {
      print('Error calculating profit for date range: $e');
      return 0.0;
    }
  }
  
  /// Initialize the transaction details Excel file manually
  /// This creates the transaction_details.xlsx file with proper structure
  Future<bool> initializeTransactionDetailsFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/transaction_details.xlsx';
      final file = File(filePath);
      
      if (await file.exists()) {
        return true;
      }
      
      final excel = await _createTransactionDetailsFile(filePath);
      
      // Add sample header styling
      final sheet = excel['Transaction Details'];
      for (int i = 0; i < 9; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: '#4CAF50',
          fontColorHex: '#FFFFFF',
        );
      }
      
      // Save with styling
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error initializing transaction details file: $e');
      return false;
    }
  }
  
  /// Get transactions by category
  Future<List<Map<String, dynamic>>> getTransactionsByCategory(String category) async {
    try {
      final transactions = await loadTransactionsFromExcel();
      return transactions.where((transaction) => 
        transaction['category']?.toString().toLowerCase() == category.toLowerCase()
      ).toList();
    } catch (e) {
      print('Error getting transactions by category: $e');
      return [];
    }
  }
  
  /// Get transactions by type (income/expense)
  Future<List<Map<String, dynamic>>> getTransactionsByType(String flowType) async {
    try {
      final transactions = await loadTransactionsFromExcel();
      return transactions.where((transaction) => 
        transaction['flowType']?.toString().toLowerCase() == flowType.toLowerCase()
      ).toList();
    } catch (e) {
      print('Error getting transactions by type: $e');
      return [];
    }
  }
  
  /// Sync all sales from sales_records.xlsx to transaction_details.xlsx
  /// This ensures all sales are properly recorded as transactions for revenue tracking
  Future<bool> syncSalesToTransactions() async {
    try {
      // Load all sales from sales_records.xlsx
      final salesRecords = await loadSalesFromExcel();
      
      if (salesRecords.isEmpty) {
        print('No sales records found to sync');
        return true;
      }
      
      // Load existing transactions to avoid duplicates
      final existingTransactions = await loadTransactionsFromExcel();
      final existingReferences = existingTransactions
          .map((t) => t['reference']?.toString() ?? '')
          .where((ref) => ref.isNotEmpty)
          .toSet();
      
      for (final sale in salesRecords) {
        final saleId = sale['orderId']?.toString() ?? '';
        final customerName = sale['customerName']?.toString() ?? 'Walk-in Customer';
        final totalSale = sale['totalCost'] as double? ?? 0.0;
        final itemName = sale['items']?.toString() ?? 'Unknown Item';
        final quantity = sale['quantity'] as double? ?? 0.0;
        final saleDate = sale['orderDate']?.toString() ?? '';
        
        // Skip if already exists in transactions
        if (existingReferences.contains(saleId)) {
          continue;
        }
        
        // Convert sale date string to DateTime
        DateTime transactionDate = DateTime.now();
        try {
          if (saleDate.isNotEmpty) {
            transactionDate = DateTime.parse(saleDate);
          }
        } catch (e) {
          print('Could not parse date $saleDate, using current date');
        }
        
        // Create transaction record for this sale
        await saveTransactionToExcel(
          transactionType: 'sale',
          partyName: customerName,
          amount: totalSale, // Positive amount for revenue
          description: 'Sale of ${quantity}x $itemName',
          reference: saleId,
          category: 'Sales Revenue',
          transactionDate: transactionDate,
          vatRate: 10.0, // 10% VAT rate
          vatAmount: null, // Legacy sales may not have VAT data
        );
        
        // Transaction synced (removed logging)
      }
      
      return true;
      
    } catch (e) {
      print('Error syncing sales to transactions: $e');
      return false;
    }
  }
  
  /// Save payment received record to payment_received.xlsx
  /// This tracks all payments received for business transactions
  Future<bool> savePaymentReceivedToExcel({
    required String customerName,
    required String saleId,
    required double totalSellingPrice,
    required double totalProfit,
    DateTime? paymentDate,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/payment_received.xlsx';
      final file = File(filePath);

      Excel excel;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = await _createPaymentReceivedFile(filePath);
      }

      final sheet = excel['Payment Received'];
      final date = paymentDate ?? DateTime.now();
      
      // Find next empty row
      int nextRow = 1;
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          nextRow = i;
          break;
        }
        nextRow = i + 1;
      }
      
      // Add payment data with proper formatting
      _setCellValue(sheet, 0, nextRow, DateFormat('dd/MM/yyyy').format(date)); // Date of Payment
      _setCellValue(sheet, 1, nextRow, customerName); // Customer/Business Name
      _setCellValue(sheet, 2, nextRow, saleId); // Sale ID
      _setCellValue(sheet, 3, nextRow, totalSellingPrice.toStringAsFixed(2)); // Total Selling Price
      _setCellValue(sheet, 4, nextRow, totalProfit.toStringAsFixed(2)); // Total Profit
      
      // Save the file
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        print('Payment received recorded: $customerName - $saleId - ${totalSellingPrice.toStringAsFixed(2)} BHD');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error saving payment received to Excel: $e');
      return false;
    }
  }
  
  /// Load all payment received records from payment_received.xlsx
  Future<List<Map<String, dynamic>>> loadPaymentReceivedFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/payment_received.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Payment received file does not exist yet');
        return [];
      }
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Payment Received'];
      
      List<Map<String, dynamic>> payments = [];
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        final paymentDate = row[0]?.value?.toString() ?? '';
        final customerName = row[1]?.value?.toString() ?? '';
        final saleId = row[2]?.value?.toString() ?? '';
        final totalSellingPrice = double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0;
        final totalProfit = double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0;
        
        payments.add({
          'paymentDate': paymentDate,
          'customerName': customerName,
          'saleId': saleId,
          'totalSellingPrice': totalSellingPrice,
          'totalProfit': totalProfit,
        });
      }
      
      print('Loaded ${payments.length} payment records from Excel');
      return payments;
      
    } catch (e) {
      print('Error loading payment received from Excel: $e');
      return [];
    }
  }
  
  /// Create the payment_received.xlsx file with proper structure
  Future<Excel> _createPaymentReceivedFile(String filePath) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Payment Received sheet
    final sheet = excel['Payment Received'];
    
    // Set headers with proper styling
    final headers = [
      'Date of Payment',
      'Customer/Business Name',
      'Sale ID',
      'Total Selling Price',
      'Total Profit'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: '#4CAF50',
        fontColorHex: '#FFFFFF',
      );
    }
    
    // Set column widths for better visibility
    sheet.setColWidth(0, 15); // Date of Payment
    sheet.setColWidth(1, 25); // Customer/Business Name
    sheet.setColWidth(2, 12); // Sale ID
    sheet.setColWidth(3, 18); // Total Selling Price
    sheet.setColWidth(4, 15); // Total Profit
    
    // Save the file
    final bytes = excel.encode();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('Created payment received file: $filePath');
    }
    
    return excel;
  }
  
  /// Sync all sales from sales_records.xlsx to payment_received.xlsx
  /// This ensures all sales payments are properly recorded
  Future<bool> syncSalesToPaymentReceived() async {
    try {
      // Load all sales from sales_records.xlsx
      final salesRecords = await loadSalesFromExcel();
      
      if (salesRecords.isEmpty) {
        print('No sales records found to sync');
        return true;
      }
      
      // Load existing payment records to avoid duplicates
      final existingPayments = await loadPaymentReceivedFromExcel();
      final existingSaleIds = existingPayments
          .map((p) => p['saleId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      
      for (final sale in salesRecords) {
        final saleId = sale['orderId']?.toString() ?? '';
        final customerName = sale['customerName']?.toString() ?? 'Walk-in Customer';
        final totalSale = sale['totalCost'] as double? ?? 0.0;
        final profit = sale['profit'] as double? ?? 0.0;
        final saleDate = sale['orderDate']?.toString() ?? '';
        
        // Skip if already exists in payment records
        if (existingSaleIds.contains(saleId)) {
          continue;
        }
        
        // Convert sale date string to DateTime
        DateTime paymentDate = DateTime.now();
        try {
          if (saleDate.isNotEmpty) {
            paymentDate = DateTime.parse(saleDate);
          }
        } catch (e) {
          print('Could not parse date $saleDate, using current date');
        }
        
        // Create payment record for this sale
        await savePaymentReceivedToExcel(
          customerName: customerName,
          saleId: saleId,
          totalSellingPrice: totalSale,
          totalProfit: profit,
          paymentDate: paymentDate,
        );
        
        // Payment synced (removed logging)
      }
      
      return true;
      
    } catch (e) {
      print('Error syncing sales to payment received: $e');
      return false;
    }
  }
  
  /// Create the transaction_details.xlsx file with proper structure
  Future<Excel> _createTransactionDetailsFile(String filePath) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Transaction Details sheet
    final sheet = excel['Transaction Details'];
    
    // Set headers
    final headers = [
      'Transaction ID',
      'Date & Time',
      'Transaction Type',
      'Party Name',
      'Amount (BHD)',
      'VAT',
      'VAT Amount',
      'Description',
      'Reference',
      'Category',
      'Flow Type'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      _setCellValue(sheet, i, 0, headers[i]);
    }
    
    // Save the file
    final bytes = excel.encode();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('Created transaction details file: $filePath');
    }
    
    return excel;
  }

  /// Save expense record to inventory_expenses.xlsx
  Future<bool> saveExpenseToExcel({
    required DateTime expenseDate,
    required String expenseCategory,
    required String description,
    required double amount,
    required String paymentMethod,
    required String vendorName,
    String? reference,
    double? vatRate, // VAT rate percentage (e.g., 10.0 for 10%)
    double? vatAmount, // Calculated VAT amount
  }) async {
    try {
      final documentsPath = Platform.environment['USERPROFILE'] ?? '';
      final filePath = '$documentsPath\\Documents\\inventory_expenses.xlsx';
      final file = File(filePath);
      
      Excel excel;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = await _createInventoryExpensesFile(filePath);
      }
      
      final sheet = excel['Inventory Expenses'];
      
      // Generate expense ID
      final expenseId = 'EXP${DateTime.now().millisecondsSinceEpoch}';
      
      // Check for duplicates based on date, amount, and description
      bool isDuplicate = false;
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isNotEmpty && row.length >= 4) {
          final existingDate = row[1]?.value?.toString() ?? '';
          final existingAmount = double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0;
          final existingDescription = row[2]?.value?.toString() ?? '';
          
          if (existingDate == DateFormat('dd/MM/yyyy').format(expenseDate) &&
              existingAmount == amount &&
              existingDescription == description) {
            isDuplicate = true;
            break;
          }
        }
      }
      
      if (isDuplicate) {
        print('Duplicate expense record found, skipping save');
        return false;
      }
      
      // Find the next empty row
      int nextRow = sheet.maxRows;
      
      // Add the expense data
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: nextRow))
          .value = expenseId; // Expense ID
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: nextRow))
          .value = DateFormat('dd/MM/yyyy').format(expenseDate); // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: nextRow))
          .value = description; // Description
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: nextRow))
          .value = amount.toStringAsFixed(2); // Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: nextRow))
          .value = expenseCategory; // Category
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: nextRow))
          .value = paymentMethod; // Payment Method
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: nextRow))
          .value = vatRate?.toString() ?? ''; // VAT Rate
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: nextRow))
          .value = vatAmount?.toString() ?? ''; // VAT Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: nextRow))
          .value = vendorName; // Payee (previously Vendor/Supplier)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: nextRow))
          .value = reference ?? ''; // Reference
      
      // Save the file
      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        print('Expense saved successfully: $expenseId');
        
        // Also save this expense as a transaction with negative amount (money going out)
        try {
          await saveTransactionToExcel(
            transactionType: 'expense',
            partyName: vendorName.isNotEmpty ? vendorName : 'Unknown Vendor',
            amount: -amount, // Negative amount since we're paying money out
            description: description,
            reference: expenseId,
            category: expenseCategory,
            transactionDate: expenseDate,
            vatRate: vatRate, // Include VAT information
            vatAmount: vatAmount,
          );
          print('Expense transaction saved: -${amount.toStringAsFixed(3)} BHD');
        } catch (e) {
          print('Warning: Failed to save expense transaction: $e');
          // Don't fail the entire operation if transaction save fails
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error saving expense to Excel: $e');
      return false;
    }
  }

  /// Load all expense records from inventory_expenses.xlsx
  Future<List<Map<String, dynamic>>> loadExpensesFromExcel() async {
    try {
      final documentsPath = Platform.environment['USERPROFILE'] ?? '';
      final filePath = '$documentsPath\\Documents\\inventory_expenses.xlsx';
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('Inventory expenses file does not exist yet');
        return [];
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final sheet = excel['Inventory Expenses'];

      final List<Map<String, dynamic>> expensesList = [];
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        
        if (row.isNotEmpty && row.length >= 4) {
          final expenseData = {
            'expenseId': row[0]?.value?.toString() ?? '', // Expense ID
            'expenseDate': row[1]?.value?.toString() ?? '', // Date
            'description': row[2]?.value?.toString() ?? '', // Description
            'amount': row[3]?.value?.toString() ?? '0', // Amount
            'category': row[4]?.value?.toString() ?? '', // Category
            'paymentMethod': row[5]?.value?.toString() ?? '', // Payment Method
            'vatRate': row[6]?.value?.toString() ?? '', // VAT Rate
            'vatAmount': row[7]?.value?.toString() ?? '', // VAT Amount
            'vendorName': row[8]?.value?.toString() ?? '', // Payee (was Vendor)
            'reference': row[9]?.value?.toString() ?? '', // Reference
          };
          
          expensesList.add(expenseData);
        }
      }
      
      print('Loaded ${expensesList.length} expense records');
      return expensesList;
    } catch (e) {
      print('Error loading expenses from Excel: $e');
      return [];
    }
  }

  /// Create the inventory_expenses.xlsx file with proper structure
  Future<Excel> _createInventoryExpensesFile(String filePath) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Inventory Expenses sheet
    final Sheet expensesSheet = excel['Inventory Expenses'];
    
    // Add column headers with VAT support
    final headers = [
      'Expense ID',
      'Date',
      'Description',
      'Amount',
      'Category',
      'Payment Method',
      'VAT',
      'VAT Amount',
      'Payee',
      'Reference',
    ];
    
    // Add headers to the first row
    for (int i = 0; i < headers.length; i++) {
      expensesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = headers[i];
    }
    
    // Save the file
    final bytes = excel.encode();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('Created inventory expenses file: $filePath');
    }
    
    return excel;
  }

  /// Get expense summary by category
  Future<Map<String, double>> getExpenseSummaryByCategory() async {
    try {
      final expenses = await loadExpensesFromExcel();
      final Map<String, double> summary = {};
      
      for (final expense in expenses) {
        final category = expense['category']?.toString() ?? 'Uncategorized';
        final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
        
        summary[category] = (summary[category] ?? 0.0) + amount;
      }
      
      return summary;
    } catch (e) {
      print('Error getting expense summary: $e');
      return {};
    }
  }

  /// Get total expenses for a date range
  Future<double> getTotalExpensesForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await loadExpensesFromExcel();
      double total = 0.0;
      
      for (final expense in expenses) {
        final dateStr = expense['expenseDate']?.toString() ?? '';
        DateTime? expenseDate;
        try {
          expenseDate = DateFormat('dd/MM/yyyy').parse(dateStr);
        } catch (e) {
          continue; // Skip invalid dates
        }
        
        if (expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(endDate.add(const Duration(days: 1)))) {
          final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
          total += amount;
        }
      }
      
      return total;
    } catch (e) {
      print('Error calculating total expenses: $e');
      return 0.0;
    }
  }

  /// Create a new vendors Excel file with proper structure
  Future<Excel> _createVendorsFile(String filePath) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create Vendors sheet
    final Sheet vendorsSheet = excel['Vendors'];
    
    // Add column headers
    final headers = [
      'Vendor ID',
      'Vendor Name',
      'Email',
      'Phone',
      'Address',
      'City',
      'Country',
      'VAT Number',
      'Maximum Credit (BHD)',
      'Current Credit (BHD)',
      'Notes',
      'Status',
      'Date Added',
      'Total Purchases (BHD)',
      'Last Purchase Date',
    ];
    
    // Add header styling
    for (var i = 0; i < headers.length; i++) {
      final cell = vendorsSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: '#4CAF50',
        fontColorHex: '#FFFFFF',
      );
    }
    
    // Save the file
    final bytes = excel.encode();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('Created vendors file: $filePath');
    }
    
    return excel;
  }

  // Save purchase to Excel (inventory_purchase_details.xlsx)
  Future<bool> savePurchaseToExcel(Map<String, dynamic> purchaseData) async {
    try {
      print('ExcelService: Starting savePurchaseToExcel');
      print('ExcelService: Purchase data received: ${purchaseData.keys}');
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${documentsDir.path}/inventory_purchase_details.xlsx';
      print('ExcelService: File path: $filePath');
      
      Excel excel;
      
      // Try to load existing file or create new one
      if (await File(filePath).exists()) {
        print('ExcelService: Loading existing file');
        final bytes = await File(filePath).readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        print('ExcelService: Creating new file');
        excel = Excel.createExcel();
        excel.delete('Sheet1');
        
        // Create sheet with headers matching your specified structure
        final sheet = excel['Purchase_Details'];
        final headers = [
          'Purchase Id', 'Vendor Name', 'Items', 'Number of Items', 
          'Unit Cost', 'Payment Status', 'Date of Order'
        ];
        
        for (var i = 0; i < headers.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
          cell.value = headers[i];
          cell.cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: '#4CAF50',
            fontColorHex: '#FFFFFF',
          );
        }
        print('ExcelService: Headers added to new file');
      }
      
      final sheet = excel['Purchase_Details'];
      final items = purchaseData['items'] as List<Map<String, dynamic>>;
      print('ExcelService: Processing ${items.length} items for separate rows');
      
      // Add ONE row per item (each item gets its own row)
      for (var item in items) {
        final rowIndex = sheet.maxRows;
        print('ExcelService: Adding item row $rowIndex: ${item['itemName']}');

        // Normalize and format quantity (ensure numeric and pretty string)
        dynamic rawQty = item['quantity'];
        double qtyDouble = 0.0;
        if (rawQty is String) {
          qtyDouble = double.tryParse(rawQty) ?? 0.0;
        } else if (rawQty is num) {
          qtyDouble = rawQty.toDouble();
        } else {
          qtyDouble = 0.0;
        }

        // Format quantity for display: use integer form when whole number
        final qtyDisplay = (qtyDouble % 1 == 0) ? qtyDouble.toInt().toString() : qtyDouble.toString();

        // Format: Item Name x Quantity
        final itemDisplay = '${item['itemName']} x $qtyDisplay';

        final rowData = [
          purchaseData['id']?.toString() ?? '',                    // Purchase Id
          purchaseData['vendorName']?.toString() ?? '',           // Vendor Name
          itemDisplay,                                             // Items (formatted as "Item Name x Quantity")
          qtyDouble,                                               // Number of Items (actual quantity)
          item['unitCost'] ?? 0.0,                                // Unit Cost
          purchaseData['isPaid'] == true ? 'Paid' : 'Credit',     // Payment Status
          purchaseData['date']?.toString() ?? '',                 // Date of Order
        ];

        print('ExcelService: Parsed quantity for item ${item['itemName']}: raw=$rawQty, qtyDouble=$qtyDouble, qtyDisplay=$qtyDisplay');
        print('ExcelService: Row data for item ${item['itemName']}: $rowData');
        
        for (var i = 0; i < rowData.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          try {
            final value = rowData[i];
            // Convert values to Excel-compatible types
            if (value is bool) {
              cell.value = value ? 'Yes' : 'No';
            } else if (value is num) {
              cell.value = value;
            } else {
              cell.value = value?.toString() ?? '';
            }
          } catch (e) {
            print('ExcelService: Error setting cell value at column $i, row $rowIndex: $e');
            print('ExcelService: Value was: ${rowData[i]} (type: ${rowData[i].runtimeType})');
            rethrow;
          }
        }
      }
      
      // Save the file
      print('ExcelService: Encoding Excel file');
      final bytes = excel.encode();
      if (bytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        print('ExcelService: Purchase saved successfully to: $filePath');
        
        // Create transaction entry for the complete purchase
        final totalAmount = items.fold<double>(0.0, (sum, item) => 
            sum + (item['totalCost'] as num? ?? 0.0).toDouble());
        
        print('🏦 Creating transaction entry for purchase ${purchaseData['id']} - Total: $totalAmount');
        print('🏦 Transaction details: ${purchaseData['vendorName']} - ${items.length} items');
        
        // Create ONE transaction for the entire purchase (not per item)
        final transactionSuccess = await saveTransactionToExcel(
          transactionType: 'purchase',
          partyName: purchaseData['vendorName']?.toString() ?? 'Unknown Vendor',
          amount: -totalAmount, // Negative for expense (money going out)
          description: 'Purchase of ${items.length} items from ${purchaseData['vendorName']}',
          reference: purchaseData['id']?.toString(),
          category: 'Inventory Purchase',
          transactionDate: DateTime.tryParse(purchaseData['date']?.toString() ?? '') ?? DateTime.now(),
          vatRate: null, // Purchases may or may not have VAT
          vatAmount: null,
        );
        
        if (transactionSuccess) {
          print('✅ Transaction logged successfully for purchase ${purchaseData['id']}');
        } else {
          print('❌ Failed to log transaction for purchase ${purchaseData['id']}');
        }
        
        // Update vendor credit if purchase is on credit
        print('🔍 Checking credit status: isPaid=${purchaseData['isPaid']}, paymentStatus=${purchaseData['paymentStatus']}');
        if (purchaseData['isPaid'] == false || purchaseData['paymentStatus'] == 'Credit') {
          final vendorName = purchaseData['vendorName']?.toString() ?? '';
          if (vendorName.isNotEmpty) {
            print('💳 Purchase is on credit - updating vendor credit for: $vendorName');
            print('💳 Credit amount to add: ${totalAmount.toStringAsFixed(3)} BHD');
            final creditUpdateSuccess = await updateVendorCredit(vendorName, totalAmount, 'add');
            if (creditUpdateSuccess) {
              print('✅ Vendor credit updated successfully for purchase ${purchaseData['id']}');
            } else {
              print('❌ Failed to update vendor credit for purchase ${purchaseData['id']}');
            }
          } else {
            print('⚠️ Cannot update vendor credit - vendor name is empty');
          }
        } else {
          print('💰 Purchase is paid - no vendor credit update needed');
        }
        
        // Update vendor purchase statistics
        final vendorName = purchaseData['vendorName']?.toString() ?? '';
        if (vendorName.isNotEmpty) {
          final statsUpdateSuccess = await updateVendorPurchaseStats(vendorName, totalAmount);
          if (statsUpdateSuccess) {
            print('✅ Vendor purchase statistics updated for: $vendorName');
          } else {
            print('❌ Failed to update vendor statistics for: $vendorName');
          }
        }
        
        return true;
      } else {
        print('ExcelService: Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('ExcelService: Error saving purchase: $e');
      print('ExcelService: Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Update inventory quantity after purchase
  Future<bool> updateInventoryQuantity(String itemId, double quantityToAdd, {
    String? itemName,
    String? category,
    String? unit,
    double? unitCost,
  }) async {
    try {
      print('🔄 Starting inventory update for item $itemId with quantity $quantityToAdd');
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${documentsDir.path}/inventory_items.xlsx';
      
      Excel excel;
      
      if (!await File(filePath).exists()) {
        print('📝 Inventory items file not found, creating new file');
        excel = await _createInventoryItemsFile(filePath);
      } else {
        final bytes = await File(filePath).readAsBytes();
        excel = Excel.decodeBytes(bytes);
      }
      
      final sheet = excel['Items'];
      
      print('📊 Adding new purchase entry for item $itemId with quantity $quantityToAdd');
      print('📋 Available sheets: ${excel.sheets.keys.toList()}');
      print('📋 Current sheet name: Items, Max rows: ${sheet.maxRows}, Max cols: ${sheet.maxCols}');
      
      // Add new purchase entry row (this is purchase-based tracking, not stock balance)
      final newRowIndex = sheet.maxRows;
      
      // Get item details from existing entries if available
      String finalItemName = itemName ?? 'Unknown Item';
      String finalCategory = category ?? 'General';
      String finalUnit = unit ?? 'pcs';
      double finalUnitCost = unitCost ?? 0.0;
      
      // Look for existing item to get consistent details
      for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final idCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        final currentId = idCell.value?.toString();
        
        if (currentId == itemId) {
          // Use existing item details if not provided
          if (itemName == null) {
            final nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
            finalItemName = nameCell.value?.toString() ?? finalItemName;
          }
          if (category == null) {
            final categoryCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
            finalCategory = categoryCell.value?.toString() ?? finalCategory;
          }
          if (unit == null) {
            final unitCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
            finalUnit = unitCell.value?.toString() ?? finalUnit;
          }
          break;
        }
      }
      
      print('📝 Adding purchase entry at row $newRowIndex for $finalItemName');
      
      // Add the purchase entry (each purchase is a new row)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: newRowIndex)).value = itemId; // Item ID
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: newRowIndex)).value = finalItemName; // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: newRowIndex)).value = finalCategory; // Category
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: newRowIndex)).value = ''; // Description
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: newRowIndex)).value = ''; // SKU
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: newRowIndex)).value = ''; // Barcode
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: newRowIndex)).value = finalUnit; // Unit
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: newRowIndex)).value = quantityToAdd; // Quantity Purchased
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: newRowIndex)).value = 5.0; // Min Stock
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: newRowIndex)).value = 100.0; // Max Stock
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: newRowIndex)).value = finalUnitCost; // Cost Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: newRowIndex)).value = finalUnitCost * 1.3; // Selling Price (30% markup)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: newRowIndex)).value = ''; // Supplier
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: newRowIndex)).value = ''; // Location
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: newRowIndex)).value = 'Active'; // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: newRowIndex)).value = DateTime.now().toIso8601String(); // Purchase Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: newRowIndex)).value = DateTime.now().toIso8601String(); // Last Updated
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: newRowIndex)).value = ''; // Notes
      
      // Save the file
      final newBytes = excel.encode();
      if (newBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(newBytes);
        print('✅ Successfully added purchase entry for item $itemId ($finalItemName) with quantity $quantityToAdd');
        
        // Calculate and display new total stock
        double totalStock = 0.0;
        for (var rowIndex = 1; rowIndex <= newRowIndex; rowIndex++) {
          final idCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
          final qtyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));
          
          if (idCell.value?.toString() == itemId) {
            totalStock += double.tryParse(qtyCell.value?.toString() ?? '0') ?? 0.0;
          }
        }
        print('📊 New total stock for item $itemId: $totalStock units');
        
        return true;
      } else {
        print('❌ Failed to encode Excel file');
        return false;
      }
    } catch (e) {
      print('❌ Error updating inventory quantity: $e');
      return false;
    }
  }

  /// Debug method to check purchase file structure
  Future<void> debugPurchaseFile() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${documentsDir.path}/inventory_purchase_details.xlsx';
      
      print('🔍 DEBUG: Checking file at: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ DEBUG: File does not exist!');
        return;
      }
      
      print('✅ DEBUG: File exists');
      
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      print('📊 DEBUG: Available sheets: ${excel.tables.keys.toList()}');
      
      // Check Purchase_Details sheet
      if (excel.tables.containsKey('Purchase_Details')) {
        final sheet = excel['Purchase_Details'];
        print('📋 DEBUG: Purchase_Details sheet found');
        print('📋 DEBUG: Max rows: ${sheet.maxRows}');
        print('📋 DEBUG: Max cols: ${sheet.maxCols}');
        
        // Print first few rows
        for (int i = 0; i < (sheet.maxRows > 5 ? 5 : sheet.maxRows); i++) {
          final row = sheet.row(i);
          final rowData = row.map((cell) => cell?.value?.toString() ?? 'null').toList();
          print('📋 DEBUG: Row $i: $rowData');
        }
      } else {
        print('❌ DEBUG: Purchase_Details sheet not found!');
        print('📋 DEBUG: Available sheets: ${excel.tables.keys.toList()}');
      }
      
    } catch (e) {
      print('❌ DEBUG: Error reading file: $e');
    }
  }

  /// Load purchase data grouped by Purchase ID from inventory_purchase_details.xlsx
  /// Returns a list where each entry represents one complete purchase with all its items

  Future<List<Map<String, dynamic>>> getGroupedPurchaseHistory() async {
    try {
      print('🔍 Loading grouped purchase history from inventory_purchase_details.xlsx');
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${documentsDir.path}/inventory_purchase_details.xlsx';
      
      if (!await File(filePath).exists()) {
        print('❌ Purchase details file not found');
        return [];
      }

      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Purchase_Details'];
      
      // Group items by Purchase ID - using NEW 7-column structure
      Map<String, Map<String, dynamic>> groupedPurchases = {};
      
      // Skip header row (row 0)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty || row[0]?.value == null) continue;
        
        // NEW Excel structure (7 columns):
        final purchaseId = row[0]?.value?.toString() ?? '';        // Purchase Id
        final vendorName = row[1]?.value?.toString() ?? '';        // Vendor Name
        final itemDisplay = row[2]?.value?.toString() ?? '';       // Items (formatted as "Item Name x Quantity")
        // row[3] is Number of Items (always 1 per row) - not needed
        final unitCost = double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0; // Unit Cost
        final paymentStatus = row[5]?.value?.toString() ?? '';     // Payment Status
        final date = row[6]?.value?.toString() ?? '';              // Date of Order
        
        // Parse item name and quantity from "Item Name x Quantity" format
        String itemName = itemDisplay;
        double quantity = 1.0;
        if (itemDisplay.contains(' x ')) {
          final parts = itemDisplay.split(' x ');
          if (parts.length >= 2) {
            itemName = parts[0];
            quantity = double.tryParse(parts[1]) ?? 1.0;
          }
        }
        
        final totalCost = unitCost * quantity;
        
        // Create item data
        final itemData = {
          'itemId': '', // Not available in new structure
          'itemName': itemName,
          'quantity': quantity,
          'unit': 'pcs', // Default unit
          'unitCost': unitCost,
          'totalCost': totalCost,
        };
        
        if (groupedPurchases.containsKey(purchaseId)) {
          // Add item to existing purchase
          final purchase = groupedPurchases[purchaseId]!;
          final items = purchase['items'] as List<Map<String, dynamic>>;
          items.add(itemData);
          
          // Update totals
          purchase['totalAmount'] = (purchase['totalAmount'] as double) + totalCost;
          purchase['itemCount'] = items.length;
        } else {
          // Create new purchase entry
          groupedPurchases[purchaseId] = {
            'purchaseId': purchaseId,
            'date': date,
            'vendorId': '', // Not available in new structure
            'vendorName': vendorName,
            'notes': '', // Not available in new structure
            'status': paymentStatus == 'Paid' ? 'Completed' : 'Pending',
            'paymentStatus': paymentStatus,
            'isPaid': paymentStatus == 'Paid' ? 'true' : 'false',
            'totalAmount': totalCost,
            'itemCount': 1,
            'items': [itemData],
          };
        }
      }
      
      // Convert to list and sort by date (newest first)
      final purchasesList = groupedPurchases.values.toList();
      purchasesList.sort((a, b) {
        try {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          return 0;
        }
      });
      
      print('✅ Loaded ${purchasesList.length} grouped purchases from NEW structure');
      for (final purchase in purchasesList) {
        print('   📦 ${purchase['purchaseId']}: ${purchase['vendorName']} - ${purchase['itemCount']} items - BHD ${(purchase['totalAmount'] as double).toStringAsFixed(2)}');
      }
      
      return purchasesList;
    } catch (e) {
      print('❌ Error loading grouped purchase history: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get vendor names for dropdown selection
  Future<List<String>> getVendorNames() async {
    try {
      final vendors = await loadVendorsFromExcel();
      return vendors
          .where((vendor) => vendor['status']?.toString() == 'Active')
          .map((vendor) => vendor['vendorName']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting vendor names: $e');
      return [];
    }
  }

  /// Add a simple vendor with just the name
  Future<void> addVendor(String vendorName) async {
    try {
      final vendorData = {
        'vendorName': vendorName,
        'email': '',
        'phone': '',
        'address': '',
        'city': '',
        'country': '',
        'vatNumber': '',
        'maximumCredit': 0.0,
        'currentCredit': 0.0,
        'notes': 'Added from expense form',
        'status': 'Active',
        'totalPurchases': 0.0,
        'lastPurchaseDate': '',
      };
      
      final success = await addVendorToExcel(vendorData);
      if (!success) {
        throw Exception('Failed to add vendor to Excel');
      }
      
      print('Vendor added successfully: $vendorName');
    } catch (e) {
      print('Error adding vendor: $e');
      throw e;
    }
  }

  /// Get vendor outstanding balance (current credit)
  Future<double> getVendorOutstandingBalance(String vendorName) async {
    try {
      final vendors = await loadVendorsFromExcel();
      final vendor = vendors.firstWhere(
        (v) => v['vendorName']?.toString().toLowerCase() == vendorName.toLowerCase(),
        orElse: () => {},
      );
      
      if (vendor.isEmpty) {
        print('Vendor not found: $vendorName');
        return 0.0;
      }
      
      final currentCredit = vendor['currentCredit'] as double? ?? 0.0;
      print('Outstanding balance for $vendorName: ${currentCredit.toStringAsFixed(3)} BHD');
      return currentCredit;
    } catch (e) {
      print('Error getting vendor outstanding balance for $vendorName: $e');
      return 0.0;
    }
  }

  /// Get all transactions from transaction_details Excel sheet
  Future<List<Map<String, dynamic>>> getAllTransactionsFromExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/transaction_details.xlsx';
      
      Excel excel;
      final file = File(filePath);
      
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        excel = Excel.decodeBytes(bytes);
      } else {
        print('Transaction details file does not exist: $filePath');
        return [];
      }
      
      final sheet = excel['Transaction Details'];
      
      List<Map<String, dynamic>> transactions = [];
      
      if (sheet.maxRows > 1) {
        // Process data rows (skip header row 0)
        for (int row = 1; row < sheet.maxRows; row++) {
          final rowData = sheet.row(row);
          
          // Skip empty rows
          if (rowData.isEmpty || rowData.every((cell) => cell?.value == null)) continue;
          
          try {
            Map<String, dynamic> transaction = {
              'transactionId': rowData[0]?.value?.toString() ?? '',
              'dateTime': rowData[1]?.value?.toString() ?? '',
              'transactionType': rowData[2]?.value?.toString() ?? '',
              'partyName': rowData[3]?.value?.toString() ?? '',
              'amount': rowData[4]?.value?.toString() ?? '0',
              'description': rowData[5]?.value?.toString() ?? '',
              'reference': rowData[6]?.value?.toString() ?? '',
              'category': rowData[7]?.value?.toString() ?? '',
              'flowType': rowData[8]?.value?.toString() ?? '',
            };
            
            // Only add non-empty transactions
            if (transaction['transactionId']?.isNotEmpty == true) {
              transactions.add(transaction);
            }
          } catch (e) {
            print('Error parsing transaction row $row: $e');
          }
        }
      }
      
      print('Loaded ${transactions.length} transactions from transaction_details.xlsx');
      return transactions;
      
    } catch (e) {
      print('Error loading transactions from Excel: $e');
      return [];
    }
  }

  /// Get vendor purchases from inventory_purchase_details Excel sheet
  Future<List<Map<String, dynamic>>> getVendorPurchases(String vendorName) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final purchaseFile = File('${documentsDir.path}/inventory_purchase_details.xlsx');
      
      if (!await purchaseFile.exists()) {
        print('Inventory purchase details file does not exist');
        return [];
      }
      
      final bytes = await purchaseFile.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Sheet1'];
      
      List<Map<String, dynamic>> vendorPurchases = [];
      
  if (sheet.rows.isNotEmpty) {
        // Get headers from first row
        final headerRow = sheet.rows[0];
        final headers = <String, int>{};
        
        for (var i = 0; i < headerRow.length; i++) {
          final cell = headerRow[i];
          if (cell?.value != null) {
            final headerName = cell!.value.toString().toLowerCase().replaceAll(' ', '');
            headers[headerName] = i;
          }
        }
        
        print('Purchase details headers: ${headers.keys.toList()}');
        
        // Process data rows (skip header)
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          
          // Skip empty rows
          if (row.isEmpty || row[0]?.value == null) continue;
          
          try {
            Map<String, dynamic> purchase = {};
            
            // Map columns based on headers
            final vendorNameIdx = headers['vendorname'] ?? headers['vendor'] ?? headers['suppliername'] ?? headers['supplier'];
            final itemNameIdx = headers['itemname'] ?? headers['item'] ?? headers['productname'] ?? headers['product'];
            final quantityIdx = headers['quantity'] ?? headers['qty'];
            final unitCostIdx = headers['unitcost'] ?? headers['cost'] ?? headers['price'];
            final totalCostIdx = headers['totalcost'] ?? headers['total'] ?? headers['amount'];
            final purchaseDateIdx = headers['purchasedate'] ?? headers['date'] ?? headers['datetime'];
            final invoiceNumberIdx = headers['invoicenumber'] ?? headers['invoice'] ?? headers['reference'];
            final categoryIdx = headers['category'];
            final unitIdx = headers['unit'];
            final notesIdx = headers['notes'] ?? headers['description'];
            final purchaseIdIdx = headers['purchaseid'] ?? headers['id'];
            
            // Extract data with safe null checks
            if (vendorNameIdx != null && vendorNameIdx < row.length) {
              purchase['vendorName'] = row[vendorNameIdx]?.value?.toString() ?? '';
            }
            if (itemNameIdx != null && itemNameIdx < row.length) {
              purchase['itemName'] = row[itemNameIdx]?.value?.toString() ?? '';
            }
            if (quantityIdx != null && quantityIdx < row.length) {
              purchase['quantity'] = double.tryParse(row[quantityIdx]?.value?.toString() ?? '0') ?? 0.0;
            }
            if (unitCostIdx != null && unitCostIdx < row.length) {
              purchase['unitCost'] = double.tryParse(row[unitCostIdx]?.value?.toString() ?? '0') ?? 0.0;
            }
            if (totalCostIdx != null && totalCostIdx < row.length) {
              purchase['totalCost'] = double.tryParse(row[totalCostIdx]?.value?.toString() ?? '0') ?? 0.0;
            }
            if (purchaseDateIdx != null && purchaseDateIdx < row.length) {
              purchase['purchaseDate'] = row[purchaseDateIdx]?.value?.toString() ?? '';
            }
            if (invoiceNumberIdx != null && invoiceNumberIdx < row.length) {
              purchase['invoiceNumber'] = row[invoiceNumberIdx]?.value?.toString() ?? '';
            }
            if (categoryIdx != null && categoryIdx < row.length) {
              purchase['category'] = row[categoryIdx]?.value?.toString() ?? '';
            }
            if (unitIdx != null && unitIdx < row.length) {
              purchase['unit'] = row[unitIdx]?.value?.toString() ?? 'pcs';
            } else {
              purchase['unit'] = 'pcs';
            }
            if (notesIdx != null && notesIdx < row.length) {
              purchase['notes'] = row[notesIdx]?.value?.toString() ?? '';
            }
            if (purchaseIdIdx != null && purchaseIdIdx < row.length) {
              purchase['purchaseId'] = row[purchaseIdIdx]?.value?.toString() ?? '';
            }
            
            // Filter purchases for the specific vendor and ensure valid data
            if (purchase['vendorName']?.toString().toLowerCase() == vendorName.toLowerCase() &&
                purchase['itemName']?.toString().isNotEmpty == true) {
              vendorPurchases.add(purchase);
            }
          } catch (e) {
            print('Error parsing purchase row $i: $e');
          }
        }
      }
      
      // Sort purchases by date (newest first)
      vendorPurchases.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['purchaseDate'] ?? '');
          final dateB = DateTime.parse(b['purchaseDate'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      
      print('Loaded ${vendorPurchases.length} purchases for vendor: $vendorName');
      return vendorPurchases;
      
    } catch (e) {
      print('Error loading vendor purchases: $e');
      return [];
    }
  }

  /// Add sample inventory data for testing
  Future<void> addSampleInventoryData() async {
    final sampleItems = [
      {
        'name': 'Sample Item 1',
        'category': 'Test',
        'currentStock': '10',
        'sellingPrice': '5.00',
        'unitCost': '3.00',
        'status': 'Active',
      },
      {
        'name': 'Sample Item 2', 
        'category': 'Test',
        'currentStock': '5',
        'sellingPrice': '8.50',
        'unitCost': '6.00',
        'status': 'Active',
      },
    ];
    
    for (final item in sampleItems) {
      await saveInventoryItemToExcel(item);
    }
    
    print('✅ DEBUG: Added sample inventory data');
  }

  /// Reset/clear the inventory_items.xlsx file and recreate with proper structure
  Future<void> resetInventoryFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/inventory_items.xlsx';
      final file = File(filePath);
      
      // Delete existing file if it exists
      if (await file.exists()) {
        await file.delete();
        print('🗑️ DEBUG: Deleted existing inventory_items.xlsx file');
      }
      
      // Create new empty file with proper headers
      await _createInventoryItemsFile(filePath);
      print('✅ DEBUG: Created fresh inventory_items.xlsx file');
    } catch (e) {
      print('❌ ERROR: Failed to reset inventory file: $e');
    }
  }
}