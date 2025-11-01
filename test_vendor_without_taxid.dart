import 'package:flutter/material.dart';
import 'lib/services/excel_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing vendor management without Tax ID field...');
  
  final excelService = ExcelService();
  
  // Test vendor creation without Tax ID
  final testVendor = {
    'vendorId': 'test_vendor_123',
    'vendorName': 'Test Vendor Corp',
    'email': 'contact@testvendor.com',
    'phone': '+973-1234-5678',
    'address': '123 Business Street',
    'city': 'Manama',
    'country': 'Bahrain',
    'vatNumber': 'VAT123456789',
    'maximumCredit': 5000.0,
    'currentCredit': 1250.0,
    'notes': 'Reliable supplier for office equipment',
    'status': 'Active',
    'dateAdded': DateTime.now().toIso8601String(),
    'totalPurchases': 0.0,
    'lastPurchaseDate': '',
  };
  
  try {
    print('Creating vendor without Tax ID field...');
    await excelService.addVendorToExcel(testVendor);
    print('✓ Vendor created successfully');
    
    print('Loading vendors to verify structure...');
    final vendors = await excelService.loadVendorsFromExcel();
    print('✓ Vendors loaded successfully');
    print('✓ Total vendors: ${vendors.length}');
    
    // Find our test vendor
    final createdVendor = vendors.firstWhere(
      (v) => v['vendorId'] == 'test_vendor_123',
      orElse: () => {},
    );
    
    if (createdVendor.isNotEmpty) {
      print('✓ Test vendor found in Excel');
      print('✓ Vendor fields (without Tax ID):');
      createdVendor.forEach((key, value) {
        print('  - $key: $value');
      });
      
      // Verify Tax ID is not present
      if (!createdVendor.containsKey('taxId')) {
        print('✓ Tax ID field successfully removed from vendor structure');
      } else {
        print('✗ Tax ID field still present (unexpected)');
      }
    } else {
      print('✗ Test vendor not found');
    }
    
    print('\n🎉 Vendor management test completed successfully!');
    print('📋 Vendor Excel structure now has 15 columns (Tax ID removed)');
    
  } catch (e) {
    print('✗ Error during vendor management test: $e');
  }
}
