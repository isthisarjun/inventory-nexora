import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/excel_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final excelService = ExcelService();
  
  print('🚀 Testing Transaction Details System...\n');
  
  // 1. Initialize the transaction details file
  print('1. Initializing transaction details Excel file...');
  final success = await excelService.initializeTransactionDetailsFile();
  if (success) {
    print('✅ Transaction details file created successfully!\n');
  } else {
    print('❌ Failed to create transaction details file\n');
    return;
  }
  
  // 2. Add sample transactions
  print('2. Adding sample transactions...');
  
  // Sample Sale Transaction (Income - Positive)
  await excelService.saveTransactionToExcel(
    transactionType: 'sale',
    partyName: 'Ahmed Al-Rashid',
    amount: 250.750, // Positive for income
    description: 'Sale of 5x Fabric Rolls (Cotton)',
    reference: 'SALE-001',
    category: 'Sales Revenue',
    transactionDate: DateTime.now(),
  );
  
  // Sample Purchase Transaction (Expense - Negative)
  await excelService.saveTransactionToExcel(
    transactionType: 'purchase',
    partyName: 'Textile Suppliers LLC',
    amount: -800.000, // Negative for expense
    description: 'Purchase of 10x Premium Fabric Rolls',
    reference: 'PUR-001',
    category: 'Inventory Purchase',
    transactionDate: DateTime.now().subtract(const Duration(days: 2)),
  );
  
  // Sample Salary Payment (Expense - Negative)
  await excelService.saveTransactionToExcel(
    transactionType: 'salary',
    partyName: 'Mohammed Hassan (Tailor)',
    amount: -450.000, // Negative for expense
    description: 'Monthly salary payment',
    reference: 'SAL-001',
    category: 'Salary',
    transactionDate: DateTime.now().subtract(const Duration(days: 1)),
  );
  
  // Sample Customer Payment (Income - Positive)
  await excelService.saveTransactionToExcel(
    transactionType: 'payment_received',
    partyName: 'Fatima Al-Zahra',
    amount: 125.500, // Positive for income
    description: 'Payment received for custom dress order',
    reference: 'PAY-001',
    category: 'Customer Payment',
    transactionDate: DateTime.now(),
  );
  
  print('✅ Sample transactions added!\n');
  
  // 3. Load and display all transactions
  print('3. Loading all transactions...');
  final transactions = await excelService.loadTransactionsFromExcel();
  
  if (transactions.isNotEmpty) {
    print('📊 Transaction Summary:');
    print('═' * 80);
    
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final amount = transaction['amount'] as double? ?? 0.0;
      
      if (amount > 0) {
        totalIncome += amount;
      } else {
        totalExpense += amount.abs();
      }
      
      print('${i + 1}. ${transaction['partyName']} | ${transaction['transactionType']} | ${amount > 0 ? '+' : ''}${amount.toStringAsFixed(3)} BHD | ${transaction['description']}');
    }
    
    print('═' * 80);
    print('💰 Total Income: +${totalIncome.toStringAsFixed(3)} BHD');
    print('💸 Total Expenses: -${totalExpense.toStringAsFixed(3)} BHD');
    print('📈 Net Profit: ${(totalIncome - totalExpense).toStringAsFixed(3)} BHD');
  } else {
    print('❌ No transactions found');
  }
  
  // 4. Test profit calculation
  print('\n4. Testing profit calculation...');
  final totalProfit = await excelService.getTotalProfit();
  print('🎯 Total Profit (from method): ${totalProfit.toStringAsFixed(3)} BHD');
  
  print('\n🎉 Transaction system test completed successfully!');
  
  exit(0);
}
