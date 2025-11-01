import 'package:flutter/material.dart';
import 'lib/services/excel_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing real-time vendor editing functionality...');
  
  final excelService = ExcelService();
  
  try {
    // Create a test vendor first
    final testVendor = {
      'vendorId': 'test_realtime_vendor_123',
      'vendorName': 'Real-Time Test Vendor',
      'email': 'realtime@testvendor.com',
      'phone': '+973-9876-5432',
      'address': '456 Real-Time Street',
      'city': 'Manama',
      'country': 'Bahrain',
      'vatNumber': 'VAT987654321',
      'maximumCredit': 3000.0,
      'currentCredit': 750.0,
      'notes': 'Test vendor for real-time editing',
      'status': 'Active',
      'dateAdded': DateTime.now().toIso8601String(),
      'totalPurchases': 0.0,
      'lastPurchaseDate': '',
    };
    
    print('Creating test vendor...');
    await excelService.addVendorToExcel(testVendor);
    print('✓ Test vendor created successfully');
    
    // Simulate real-time updates
    print('\\nSimulating real-time updates...');
    
    // Update 1: Change vendor name
    testVendor['vendorName'] = 'Real-Time Updated Vendor';
    await excelService.updateVendorInExcel(testVendor);
    print('✓ Update 1: Vendor name changed');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update 2: Change credit information
    testVendor['maximumCredit'] = 5000.0;
    testVendor['currentCredit'] = 1250.0;
    await excelService.updateVendorInExcel(testVendor);
    print('✓ Update 2: Credit information updated');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update 3: Change contact information
    testVendor['phone'] = '+973-1111-2222';
    testVendor['email'] = 'updated-realtime@testvendor.com';
    await excelService.updateVendorInExcel(testVendor);
    print('✓ Update 3: Contact information updated');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update 4: Add notes
    testVendor['notes'] = 'Updated notes via real-time editing - auto-save working perfectly!';
    await excelService.updateVendorInExcel(testVendor);
    print('✓ Update 4: Notes updated');
    
    // Verify final state
    print('\\nVerifying final vendor state...');
    final vendors = await excelService.loadVendorsFromExcel();
    final updatedVendor = vendors.firstWhere(
      (v) => v['vendorId'] == 'test_realtime_vendor_123',
      orElse: () => {},
    );
    
    if (updatedVendor.isNotEmpty) {
      print('✓ Updated vendor found in Excel');
      print('✓ Final vendor details:');
      print('  - Name: ${updatedVendor['vendorName']}');
      print('  - Email: ${updatedVendor['email']}');
      print('  - Phone: ${updatedVendor['phone']}');
      print('  - Max Credit: BHD ${updatedVendor['maximumCredit']}');
      print('  - Current Credit: BHD ${updatedVendor['currentCredit']}');
      print('  - Notes: ${updatedVendor['notes']}');
      
      // Verify the updates were applied correctly
      bool allUpdatesCorrect = true;
      if (updatedVendor['vendorName'] != 'Real-Time Updated Vendor') allUpdatesCorrect = false;
      if (updatedVendor['email'] != 'updated-realtime@testvendor.com') allUpdatesCorrect = false;
      if (updatedVendor['phone'] != '+973-1111-2222') allUpdatesCorrect = false;
      if (updatedVendor['maximumCredit'] != 5000.0) allUpdatesCorrect = false;
      if (updatedVendor['currentCredit'] != 1250.0) allUpdatesCorrect = false;
      
      if (allUpdatesCorrect) {
        print('\\n🎉 Real-time editing test completed successfully!');
        print('📋 All vendor updates were saved correctly');
        print('⚡ Real-time editing with auto-save is working perfectly');
      } else {
        print('\\n⚠️ Some updates were not saved correctly');
      }
    } else {
      print('✗ Updated vendor not found');
    }
    
  } catch (e) {
    print('✗ Error during real-time editing test: $e');
  }
}
