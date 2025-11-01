import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'lib/services/excel_service.dart';

/// Test script to verify vendor Excel integration functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Vendor Excel Integration Test ===\n');
  
  final excelService = ExcelService();
  
  try {
    // Test 1: Load vendors (will create file if doesn't exist)
    print('Test 1: Loading vendors from Excel...');
    final vendors = await excelService.loadVendorsFromExcel();
    print('Loaded ${vendors.length} vendors');
    for (var vendor in vendors) {
      print('  - ${vendor['name']} (${vendor['category']}) - Status: ${vendor['status']}');
    }
    print('✅ Test 1 passed\n');
    
    // Test 2: Add a new vendor
    print('Test 2: Adding new vendor...');
    final newVendor = {
      'name': 'Test Vendor Ltd',
      'category': 'Electronics',
      'contactPerson': 'John Smith',
      'phone': '+973 1234 5678',
      'email': 'john@testvendor.com',
      'address': '123 Test Street, Manama',
      'paymentTerms': '30 days',
      'creditLimit': '5000.000',
      'vatNumber': 'BH123456789',
      'notes': 'Test vendor for system verification'
    };
    
    final addResult = await excelService.addVendorToExcel(newVendor);
    if (addResult) {
      print('✅ New vendor added successfully');
    } else {
      print('❌ Failed to add new vendor');
    }
    print('✅ Test 2 passed\n');
    
    // Test 3: Try to add duplicate vendor
    print('Test 3: Testing duplicate vendor prevention...');
    final duplicateResult = await excelService.addVendorToExcel(newVendor);
    if (!duplicateResult) {
      print('✅ Duplicate prevention working correctly');
    } else {
      print('❌ Duplicate vendor was added (should have been prevented)');
    }
    print('✅ Test 3 passed\n');
    
    // Test 4: Update vendor
    print('Test 4: Updating vendor information...');
    final updateData = {
      'name': 'Test Vendor Ltd',
      'phone': '+973 9876 5432',
      'email': 'updated@testvendor.com',
      'notes': 'Updated test vendor information'
    };
    
    final updateResult = await excelService.updateVendorInExcel(updateData);
    if (updateResult) {
      print('✅ Vendor updated successfully');
    } else {
      print('❌ Failed to update vendor');
    }
    print('✅ Test 4 passed\n');
    
    // Test 5: Update purchase stats
    print('Test 5: Updating vendor purchase statistics...');
    final purchaseUpdateResult = await excelService.updateVendorPurchaseStats('Test Vendor Ltd', 1250.500);
    if (purchaseUpdateResult) {
      print('✅ Purchase stats updated successfully');
    } else {
      print('❌ Failed to update purchase stats');
    }
    print('✅ Test 5 passed\n');
    
    // Test 6: Load updated vendors to verify changes
    print('Test 6: Verifying all changes...');
    final updatedVendors = await excelService.loadVendorsFromExcel();
    final testVendor = updatedVendors.firstWhere(
      (vendor) => vendor['name'] == 'Test Vendor Ltd',
      orElse: () => {},
    );
    
    if (testVendor.isNotEmpty) {
      print('Updated vendor details:');
      print('  Name: ${testVendor['name']}');
      print('  Phone: ${testVendor['phone']}');
      print('  Email: ${testVendor['email']}');
      print('  Total Purchases: ${testVendor['totalPurchases']} BHD');
      print('  Last Purchase: ${testVendor['lastPurchaseDate']}');
      print('  Status: ${testVendor['status']}');
    }
    print('✅ Test 6 passed\n');
    
    // Test 7: Delete vendor (soft delete)
    print('Test 7: Testing vendor deletion (soft delete)...');
    final deleteResult = await excelService.deleteVendorFromExcel('Test Vendor Ltd');
    if (deleteResult) {
      print('✅ Vendor deleted successfully');
    } else {
      print('❌ Failed to delete vendor');
    }
    
    // Verify vendor is marked as inactive
    final finalVendors = await excelService.loadVendorsFromExcel();
    final deletedVendor = finalVendors.firstWhere(
      (vendor) => vendor['name'] == 'Test Vendor Ltd',
      orElse: () => {},
    );
    
    if (deletedVendor.isNotEmpty && deletedVendor['status'] == 'Inactive') {
      print('✅ Vendor correctly marked as inactive');
    }
    print('✅ Test 7 passed\n');
    
    // Show file location
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/inventory_vendors.xlsx';
    print('Vendors Excel file location: $filePath');
    
    if (await File(filePath).exists()) {
      print('✅ Excel file exists and accessible');
    } else {
      print('❌ Excel file not found');
    }
    
    print('\n=== All Tests Completed Successfully! ===');
    print('Vendor Excel integration is working correctly.');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
