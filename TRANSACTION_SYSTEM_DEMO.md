// Transaction Management System Demo

// Example usage of the new transaction system:

/*
=== TRANSACTION DETAILS EXCEL SHEET ===

The system creates a file called "transaction_details.xlsx" with these columns:

| Transaction ID | Date & Time     | Transaction Type | Party Name           | Amount (BHD) | Description                    | Reference | Category           | Flow Type |
|---------------|-----------------|------------------|---------------------|--------------|--------------------------------|-----------|-------------------|-----------|
| TXN123456     | 10/08/2025 14:30| sale            | Ahmad Al-Mansoori    | +250.750     | Sale of custom suit           | SALE-001  | Sales             | Income    |
| TXN123457     | 10/08/2025 15:15| payment_received| Fatima Al-Rashid    | +125.500     | Payment for previous order    | PAY-001   | Customer Payment  | Income    |
| TXN123458     | 10/08/2025 16:00| salary          | Mohamed Hassan       | -800.000     | Monthly salary payment         | SAL-001   | Salary            | Expense   |
| TXN123459     | 10/08/2025 16:30| supplier_payment| Bahrain Fabrics      | -320.250     | Payment for fabric purchase    | SUP-001   | Inventory Purchase| Expense   |
| TXN123460     | 10/08/2025 17:00| expense         | Al-Manamah Properties| -500.000     | Monthly shop rent              | RENT-001  | Rent              | Expense   |

=== KEY FEATURES ===

✅ POSITIVE amounts (+) = Money coming IN (sales, payments received)
✅ NEGATIVE amounts (-) = Money going OUT (expenses, salaries, supplier payments)
✅ Automatic profit calculation = Sum of all amounts
✅ Comprehensive transaction tracking with party names
✅ Reference linking to other systems (Sale IDs, Invoice IDs, etc.)
✅ Category-based filtering and reporting
✅ Date-based profit analysis

=== USAGE EXAMPLES ===

// 1. Record a sale
await excelService.saveTransactionToExcel(
  transactionType: 'sale',
  partyName: 'Customer Name',
  amount: 150.000, // Positive for income
  description: 'Sale of tailoring services',
  reference: 'SALE-001',
  category: 'Sales',
);

// 2. Record supplier payment
await excelService.saveTransactionToExcel(
  transactionType: 'supplier_payment',
  partyName: 'Fabric Supplier LLC',
  amount: -200.000, // Negative for expense
  description: 'Payment for fabric purchase',
  reference: 'PO-001',
  category: 'Inventory Purchase',
);

// 3. Record salary payment
await excelService.saveTransactionToExcel(
  transactionType: 'salary',
  partyName: 'Employee Name',
  amount: -600.000, // Negative for expense
  description: 'Monthly salary',
  category: 'Salary',
);

// 4. Get total profit/loss
final totalProfit = await excelService.getTotalProfit();
print('Total Profit: ${totalProfit.toStringAsFixed(3)} BHD');

// 5. Get transactions by category
final salesTransactions = await excelService.getTransactionsByCategory('Sales');
final salaryExpenses = await excelService.getTransactionsByCategory('Salary');

// 6. Get income vs expenses
final incomeTransactions = await excelService.getTransactionsByType('Income');
final expenseTransactions = await excelService.getTransactionsByType('Expense');

=== PROFIT CALCULATION ===

Total Profit = Sum of all transaction amounts
Example:
  Sales:     +250.750 + 125.500 = +376.250 BHD (Income)
  Expenses:  -800.000 - 320.250 - 500.000 = -1,620.250 BHD (Expenses)
  Net Profit: 376.250 - 1,620.250 = -1,244.000 BHD (Loss)

=== INTEGRATION PLAN ===

Next steps will be to link this transaction system with:
1. Sales records - Auto-create transaction when sale is made
2. Supplier payments - Auto-record when paying suppliers
3. Salary system - Auto-record salary payments
4. Expense tracking - Link with existing expense screens
5. Financial reports - Generate profit/loss statements

*/
