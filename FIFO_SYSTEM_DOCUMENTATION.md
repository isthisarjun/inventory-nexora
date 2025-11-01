# FIFO (First In, First Out) Batch Costing System

Your inventory management system already includes a comprehensive FIFO batch costing implementation that automatically handles cost calculation and profit tracking when making sales.

## How the FIFO System Works

### 1. **Batch Creation**
When you add inventory using the purchase-based system:
```dart
// Each purchase creates a new batch with its own cost price
await excelService.addStockPurchaseEntry(
  itemId: 'ITM001',
  quantity: 100.0,
  costPrice: 5.50,
  supplier: 'Supplier A'
);
```

This automatically:
- Creates a new entry in `inventory_items.xlsx`
- Creates a corresponding batch in `inventory_batches.xlsx` with:
  - Unique batch ID
  - Purchase date (for FIFO ordering)
  - Quantity purchased and remaining
  - Cost price for this specific batch
  - Supplier information

### 2. **FIFO Sales Processing**
When a sale is made:
```dart
final saleData = {
  'saleId': 'SALE001',
  'date': DateTime.now().toIso8601String(),
  'items': [
    {
      'itemId': 'ITM001',
      'itemName': 'Product A',
      'quantity': 12.0,
      'sellingPrice': 10.00,
    }
  ]
};

await excelService.saveSaleToExcel(saleData);
```

The system automatically:
1. **Sorts batches by purchase date** (oldest first)
2. **Consumes inventory from oldest batches first**
3. **Calculates weighted average cost** based on consumed batches
4. **Updates remaining quantities** in each batch
5. **Records detailed sale information** including profit

### 3. **FIFO Example**

**Initial Inventory:**
- Batch 1: 10 units @ $5.00 each (oldest)
- Batch 2: 15 units @ $6.00 each 
- Batch 3: 20 units @ $7.00 each (newest)

**Sale: 12 units @ $10.00 each**

FIFO Logic:
- Takes 10 units from Batch 1 @ $5.00 = $50.00
- Takes 2 units from Batch 2 @ $6.00 = $12.00
- **Total Cost:** $62.00
- **Weighted Average Cost:** $62.00 ÷ 12 = $5.17 per unit
- **Revenue:** 12 × $10.00 = $120.00
- **Profit:** $120.00 - $62.00 = $58.00

**After Sale:**
- Batch 1: 0 units remaining (fully consumed)
- Batch 2: 13 units @ $6.00 each remaining
- Batch 3: 20 units @ $7.00 each (untouched)

## Excel Files Structure

### 1. `inventory_items.xlsx`
Contains purchase entries (each row = one purchase):
- Item ID, Name, Category
- **Quantity purchased in this batch**
- **Cost price for this specific purchase**
- Purchase date, Supplier
- Notes

### 2. `inventory_batches.xlsx`
Tracks FIFO batches:
- Batch ID (unique identifier)
- Item ID (links to inventory)
- Purchase Date (for FIFO sorting)
- Qty Purchased, **Qty Remaining**
- **Cost Price for this batch**
- Supplier, Notes

### 3. `sales_records.xlsx`
Records each sale with FIFO costing:
- Sale ID, Date
- Item ID, Item Name
- Quantity Sold, Selling Price
- **Batch Cost Price (FIFO calculated)**
- Total Cost, Total Sale
- **Profit (automatically calculated)**

## Key Features

### ✅ **Automatic FIFO Processing**
- Oldest batches consumed first
- No manual intervention needed
- Handles partial batch consumption

### ✅ **Accurate Cost Tracking**
- Each purchase maintains its own cost price
- Weighted average cost calculation
- Handles multiple suppliers with different prices

### ✅ **Real-time Profit Calculation**
- Profit = Selling Price - FIFO Cost
- Accounts for actual cost of goods sold
- More accurate than average costing methods

### ✅ **Inventory Updates**
- Batch quantities automatically updated
- Main inventory reflects current stock
- Prevents overselling

### ✅ **Detailed Reporting**
- Complete audit trail of costs
- Batch-level tracking
- Sale-by-sale profit analysis

## API Functions

### Preview FIFO Cost (before sale)
```dart
final analysis = await excelService.getFIFOCostAnalysis('ITM001', 15.0);
print('Can fulfill: ${analysis['canFulfill']}');
print('Total cost would be: \$${analysis['totalCost']}');
print('Breakdown: ${analysis['breakdown']}');
```

### Get Item Batches
```dart
final batches = await excelService.getInventoryBatches('ITM001');
for (final batch in batches) {
  print('Batch: ${batch['qtyRemaining']} @ \$${batch['costPrice']}');
}
```

### Record Sale (automatic FIFO)
```dart
await excelService.saveSaleToExcel(saleData);
// FIFO processing happens automatically
```

## Benefits of This Implementation

1. **Accurate Profitability:** True cost of goods sold
2. **Regulatory Compliance:** FIFO is accepted accounting method
3. **Inflation Handling:** Older, lower costs used first
4. **Inventory Valuation:** Remaining stock valued at recent costs
5. **Supplier Tracking:** Know which supplier's goods were sold
6. **Audit Trail:** Complete history of cost basis

Your system is already fully implementing this sophisticated FIFO costing method automatically!
