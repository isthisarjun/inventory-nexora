import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/services/excel_service.dart';

class OrderItem {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final FocusNode itemDropdownFocus = FocusNode();
  final FocusNode itemNameFocus = FocusNode();
  final FocusNode quantityFocus = FocusNode();
  final FocusNode priceFocus = FocusNode();
  
  Map<String, dynamic>? selectedItem;
  
  double get totalPrice {
    final quantity = double.tryParse(quantityController.text) ?? 0.0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
    return quantity * unitPrice;
  }
  
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    itemDropdownFocus.dispose();
    itemNameFocus.dispose();
    quantityFocus.dispose();
    priceFocus.dispose();
  }
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _excelService = ExcelService();
  
  // Controllers for form fields
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final _customerNameFocus = FocusNode();
  final _customerPhoneFocus = FocusNode();
  final _customerAddressFocus = FocusNode();
  final _createOrderButtonFocus = FocusNode();
  
  // Payment method and status
  String _selectedPaymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'Card', 'Benefit'];
  bool _isPaid = true; // Default to paid
  
  // Calculated values
  double _subtotal = 0.0;
  double _vatAmount = 0.0;
  double _finalPrice = 0.0;
  
  // Inventory data
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoadingItems = true;
  
  // Order items list
  final List<OrderItem> _orderItems = [OrderItem()];
  
  @override
  void initState() {
    super.initState();
    
    // Add listeners to update calculations for each order item
    for (var orderItem in _orderItems) {
      orderItem.quantityController.addListener(_updateCalculations);
      orderItem.unitPriceController.addListener(_updateCalculations);
    }
    
    // Load inventory items
    _loadInventoryItems();
  }
  
  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoadingItems = true;
    });
    
    try {
      print('🔍 DEBUG: Starting to load inventory items...');
      final items = await _excelService.loadInventoryItemsFromExcel();
      print('🔍 DEBUG: Loaded ${items.length} inventory items');
      
      // Log first few items for debugging
      if (items.isNotEmpty) {
        print('🔍 DEBUG: First item: ${items[0]}');
      }
      
      setState(() {
        // Filter items that have stock available (currentStock > 0)
        _inventoryItems = items.where((item) {
          final currentStock = double.tryParse(item['currentStock'].toString()) ?? 0.0;
          print('🔍 DEBUG: Item ${item['name']} has stock: $currentStock');
          return currentStock > 0;
        }).toList();
        _isLoadingItems = false;
      });
      
      print('🔍 DEBUG: Filtered to ${_inventoryItems.length} items with stock > 0');
    } catch (e) {
      print('❌ ERROR: Failed to load inventory items: $e');
      setState(() {
        _isLoadingItems = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory items: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    // Dispose controllers
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    
    // Dispose focus nodes
    _customerNameFocus.dispose();
    _customerPhoneFocus.dispose();
    _customerAddressFocus.dispose();
    _createOrderButtonFocus.dispose();
    
    // Dispose all order items
    for (var orderItem in _orderItems) {
      orderItem.dispose();
    }
    
    super.dispose();
  }
  
  void _onItemSelected(Map<String, dynamic>? item, int index) {
    setState(() {
      _orderItems[index].selectedItem = item;
      if (item != null) {
        _orderItems[index].itemNameController.text = item['name'].toString();
        _orderItems[index].unitPriceController.text = (double.tryParse(item['sellingPrice'].toString()) ?? 0.0).toString();
        _updateCalculations();
      } else {
        // User selected "Add New Item" - show the add new item dialog
        _orderItems[index].itemNameController.clear();
        _orderItems[index].unitPriceController.clear();
        _updateCalculations();
        
        // Show the add new item dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddNewItemDialog(index);
        });
      }
    });
  }
  
  void _updateCalculations() {
    setState(() {
      // Calculate subtotal from all order items (VAT-inclusive prices)
      _subtotal = _orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      // VAT-inclusive pricing: Unit prices include 10% VAT
      // Base Price = Total Price ÷ 1.10, VAT Amount = Base Price × 0.10
      final basePriceSubtotal = _subtotal / 1.10;
      _vatAmount = basePriceSubtotal * 0.10;
      
      // Final price remains the same as subtotal since VAT is already included
      _finalPrice = _subtotal;
    });
  }
  
  void _addOrderItem() {
    setState(() {
      final newItem = OrderItem();
      newItem.quantityController.addListener(_updateCalculations);
      newItem.unitPriceController.addListener(_updateCalculations);
      _orderItems.add(newItem);
      
      // Focus the new item's dropdown after adding
      WidgetsBinding.instance.addPostFrameCallback((_) {
        newItem.itemDropdownFocus.requestFocus();
      });
    });
  }
  
  void _removeOrderItem(int index) {
    if (_orderItems.length > 1) {
      setState(() {
        _orderItems[index].dispose();
        _orderItems.removeAt(index);
        _updateCalculations();
      });
    }
  }

  // Handle keyboard navigation between fields
  void _handleKeyNavigation(RawKeyEvent event, FocusNode currentFocus) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight || 
          event.logicalKey == LogicalKeyboardKey.tab ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _focusNextField(currentFocus);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _focusPreviousField(currentFocus);
      }
    }
  }

  void _focusNextField(FocusNode currentFocus) {
    // Navigate through customer fields first
    if (currentFocus == _customerNameFocus) {
      _customerPhoneFocus.requestFocus();
    } else if (currentFocus == _customerPhoneFocus) {
      _customerAddressFocus.requestFocus();
    } else if (currentFocus == _customerAddressFocus) {
      // Move to first item's dropdown
      if (_orderItems.isNotEmpty) {
        _orderItems[0].itemDropdownFocus.requestFocus();
      }
    } else {
      // Navigate through order items
      for (int i = 0; i < _orderItems.length; i++) {
        final item = _orderItems[i];
        if (currentFocus == item.itemDropdownFocus) {
          if (item.selectedItem == null) {
            item.itemNameFocus.requestFocus();
          } else {
            item.quantityFocus.requestFocus();
          }
          return;
        } else if (currentFocus == item.itemNameFocus) {
          item.quantityFocus.requestFocus();
          return;
        } else if (currentFocus == item.quantityFocus) {
          item.priceFocus.requestFocus();
          return;
        } else if (currentFocus == item.priceFocus) {
          // Move to next item or stay here if last item
          if (i + 1 < _orderItems.length) {
            _orderItems[i + 1].itemDropdownFocus.requestFocus();
          }
          return;
        }
      }
    }
  }

  void _focusPreviousField(FocusNode currentFocus) {
    // Navigate backwards through customer fields
    if (currentFocus == _customerPhoneFocus) {
      _customerNameFocus.requestFocus();
    } else if (currentFocus == _customerAddressFocus) {
      _customerPhoneFocus.requestFocus();
    } else {
      // Navigate backwards through order items
      for (int i = 0; i < _orderItems.length; i++) {
        final item = _orderItems[i];
        if (currentFocus == item.itemDropdownFocus) {
          if (i == 0) {
            _customerAddressFocus.requestFocus();
          } else {
            _orderItems[i - 1].priceFocus.requestFocus();
          }
          return;
        } else if (currentFocus == item.itemNameFocus) {
          item.itemDropdownFocus.requestFocus();
          return;
        } else if (currentFocus == item.quantityFocus) {
          if (item.selectedItem == null) {
            item.itemNameFocus.requestFocus();
          } else {
            item.itemDropdownFocus.requestFocus();
          }
          return;
        } else if (currentFocus == item.priceFocus) {
          item.quantityFocus.requestFocus();
          return;
        }
      }
    }
  }

  // Show dialog to ask if user wants to add a new item
  Future<void> _showAddItemDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Add New Item",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            "Do you want to add another item to this order?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green[600]!),
              ),
              child: Text(
                "Yes",
                style: TextStyle(color: Colors.green[600]),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // User wants to add a new item
      _addOrderItem();
    } else {
      // User chose Cancel - focus the Create Order button
      // We'll handle this in the action buttons section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_createOrderButtonFocus);
      });
    }
  }

  // Show dialog to add a new inventory item
  Future<void> _showAddNewItemDialog(int orderItemIndex) async {
    // Controllers for the new item form
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final currentStockController = TextEditingController();
    final unitCostController = TextEditingController();
    final sellingPriceController = TextEditingController();
    
    // Focus nodes for navigation
    final nameFocus = FocusNode();
    final categoryFocus = FocusNode();
    final currentStockFocus = FocusNode();
    final unitCostFocus = FocusNode();
    final sellingPriceFocus = FocusNode();
    
    // Form key for validation
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Add New Inventory Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Form fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Row 1: Item Name and Category
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: nameController,
                                  focusNode: nameFocus,
                                  decoration: InputDecoration(
                                    labelText: 'Item Name *',
                                    prefixIcon: const Icon(Icons.inventory, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(categoryFocus);
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Item name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: categoryController,
                                  focusNode: categoryFocus,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: const Icon(Icons.category, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(currentStockFocus);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Row 2: Current Stock and Unit Cost
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: currentStockController,
                                  focusNode: currentStockFocus,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Current Stock *',
                                    prefixIcon: const Icon(Icons.inventory_2, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(unitCostFocus);
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Stock is required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Enter valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: unitCostController,
                                  focusNode: unitCostFocus,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Unit Cost',
                                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onFieldSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(sellingPriceFocus);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Row 3: Selling Price
                          TextFormField(
                            controller: sellingPriceController,
                            focusNode: sellingPriceFocus,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Selling Price *',
                              prefixIcon: const Icon(Icons.sell, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Selling price is required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          // Validate form using the form key
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          
                          try {
                            // Parse values safely
                            final currentStock = double.tryParse(currentStockController.text.trim()) ?? 0.0;
                            final unitCost = double.tryParse(unitCostController.text.trim()) ?? 0.0;
                            final sellingPrice = double.tryParse(sellingPriceController.text.trim()) ?? 0.0;
                            
                            if (currentStock <= 0 || sellingPrice <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stock and selling price must be greater than 0'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Create item data
                            final itemData = {
                              'name': nameController.text.trim(),
                              'category': categoryController.text.trim(),
                              'currentStock': currentStock,
                              'unitCost': unitCost,
                              'sellingPrice': sellingPrice,
                            };
                            
                            Navigator.of(context).pop(itemData);
                          } catch (e) {
                            debugPrint('Error creating item data: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error creating item: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Item'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Dispose controllers and focus nodes
    nameController.dispose();
    categoryController.dispose();
    currentStockController.dispose();
    unitCostController.dispose();
    sellingPriceController.dispose();
    nameFocus.dispose();
    categoryFocus.dispose();
    currentStockFocus.dispose();
    unitCostFocus.dispose();
    sellingPriceFocus.dispose();

    if (result != null) {
      // User filled the form - save the item to inventory
      await _addNewItemToInventory(result, orderItemIndex);
    } else {
      // User cancelled - reset the dropdown to no selection
      setState(() {
        _orderItems[orderItemIndex].selectedItem = null;
      });
    }
  }

  // Add the new item to inventory and then select it in the order
  Future<void> _addNewItemToInventory(Map<String, dynamic> itemData, int orderItemIndex) async {
    try {
      debugPrint('🔄 Adding new item to inventory: ${itemData['name']}');
      
      // Generate the next item ID
      final nextItemId = _generateNextItemId();
      debugPrint('📝 Generated item ID: $nextItemId');
      
      final fullItemData = {
        'id': nextItemId,
        'name': itemData['name']?.toString() ?? '',
        'category': itemData['category']?.toString() ?? '',
        'currentStock': (itemData['currentStock'] as num?)?.toDouble() ?? 0.0,
        'unitCost': (itemData['unitCost'] as num?)?.toDouble() ?? 0.0,
        'sellingPrice': (itemData['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        'unit': 'pcs',
        'minimumStock': 5.0,
        'maximumStock': 100.0,
        'status': 'Active',
        'description': '',
        'sku': '',
        'barcode': '',
        'supplier': '',
        'location': '',
        'notes': '',
        'dateAdded': DateTime.now().toIso8601String().split('T')[0],
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      debugPrint('💾 Saving item to Excel: $fullItemData');
      final success = await _excelService.saveInventoryItemToExcel(fullItemData);
      
      if (success) {
        // Reload inventory items to include the new item
        await _loadInventoryItems();
        
        // Find and select the newly added item
        final newItem = _inventoryItems.firstWhere(
          (item) => item['id'] == nextItemId,
          orElse: () => fullItemData,
        );
        
        setState(() {
          _orderItems[orderItemIndex].selectedItem = newItem;
          _orderItems[orderItemIndex].itemNameController.text = newItem['name'].toString();
          _orderItems[orderItemIndex].unitPriceController.text = newItem['sellingPrice'].toString();
          _updateCalculations();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Item "${itemData['name']}" added to inventory and selected'),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add item to inventory'),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Reset dropdown selection on failure
        setState(() {
          _orderItems[orderItemIndex].selectedItem = null;
        });
      }
    } catch (e) {
      debugPrint('Error adding new item to inventory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Reset dropdown selection on error
      setState(() {
        _orderItems[orderItemIndex].selectedItem = null;
      });
    }
  }

  // Generate next item ID (similar to inventory items screen)
  String _generateNextItemId() {
    try {
      if (_inventoryItems.isEmpty) {
        debugPrint('📋 No existing items, starting with ITEM001');
        return 'ITEM001';
      }
      
      // Extract numeric parts from existing IDs and find the highest
      int maxNumber = 0;
      for (final item in _inventoryItems) {
        if (item['id'] == null) continue;
        
        final id = item['id'].toString();
        final match = RegExp(r'ITEM(\d+)').firstMatch(id);
        if (match != null) {
          final number = int.tryParse(match.group(1)!) ?? 0;
          if (number > maxNumber) {
            maxNumber = number;
          }
        }
      }
      
      final nextNumber = maxNumber + 1;
      final nextId = 'ITEM${nextNumber.toString().padLeft(3, '0')}';
      debugPrint('🔢 Generated next item ID: $nextId (max found: $maxNumber)');
      return nextId;
    } catch (e) {
      debugPrint('❌ Error generating item ID: $e');
      // Fallback to timestamp-based ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'ITEM_$timestamp';
    }
  }

  // Updated payment dialog with toggle functionality
  Future<void> _showPaymentDialog() async {
    bool tempIsPaid = _isPaid;
    String? tempPaymentMethod = _isPaid ? _selectedPaymentMethod : null;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Create Order",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment status toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tempIsPaid ? Colors.green[50] : Colors.orange[50],
                        border: Border.all(
                          color: tempIsPaid ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                tempIsPaid ? Icons.check_circle : Icons.schedule,
                                color: tempIsPaid ? Colors.green : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tempIsPaid ? "PAID ORDER" : "CREDIT ORDER",
                                style: TextStyle(
                                  color: tempIsPaid ? Colors.green[700] : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Toggle Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Credit",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: !tempIsPaid ? FontWeight.bold : FontWeight.normal,
                                  color: !tempIsPaid ? Colors.orange[700] : Colors.grey,
                                ),
                              ),
                              Switch(
                                value: tempIsPaid,
                                activeThumbColor: Colors.green,
                                activeTrackColor: Colors.green[200],
                                inactiveThumbColor: Colors.orange,
                                inactiveTrackColor: Colors.orange[200],
                                onChanged: (val) {
                                  setDialogState(() {
                                    tempIsPaid = val;
                                    if (!tempIsPaid) {
                                      tempPaymentMethod = null; // Reset payment if Credit
                                    } else {
                                      tempPaymentMethod = _selectedPaymentMethod; // Restore payment method
                                    }
                                  });
                                },
                              ),
                              Text(
                                "Paid",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: tempIsPaid ? FontWeight.bold : FontWeight.normal,
                                  color: tempIsPaid ? Colors.green[700] : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Order Total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Order Total:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'BHD ${_finalPrice.toStringAsFixed(3)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment method (only shows if Paid)
                    if (tempIsPaid) ...[
                      const Text(
                        "Payment Method",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: tempPaymentMethod,
                        items: _paymentMethods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Row(
                              children: [
                                Icon(
                                  method == 'Cash' ? Icons.money :
                                  method == 'Card' ? Icons.credit_card :
                                  Icons.account_balance,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(method),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            tempPaymentMethod = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "Select payment method",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFEEEEEE),
                        ),
                      ),
                    ] else ...[
                      // Credit order message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "This order will be marked as Credit (unpaid). Payment can be collected later.",
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempIsPaid && (tempPaymentMethod == null || tempPaymentMethod!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a payment method."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'isPaid': tempIsPaid,
                      'paymentMethod': tempPaymentMethod,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tempIsPaid ? Colors.green[700] : Colors.orange[700],
                  ),
                  child: Text(
                    tempIsPaid ? "Complete Paid Order" : "Create Credit Order",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _isPaid = result['isPaid'];
        _selectedPaymentMethod = result['paymentMethod'] ?? 'Cash';
      });
      _processOrder();
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await _showPaymentDialog();
    }
  }

  void _processOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Processing order...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        // Process each order item
        bool allSuccess = true;
        List<String> itemNames = [];
        
        for (var orderItem in _orderItems) {
          // Prepare item data for inventory
          final itemData = {
            'name': orderItem.itemNameController.text.trim(),
            'category': 'General',
            'description': 'Item from order',
            'sku': '',
            'barcode': '',
            'unit': 'pcs',
            'currentStock': double.tryParse(orderItem.quantityController.text) ?? 0.0,
            'minimumStock': 0.0,
            'maximumStock': 0.0,
            'unitCost': double.tryParse(orderItem.unitPriceController.text) ?? 0.0,
            'sellingPrice': double.tryParse(orderItem.unitPriceController.text) ?? 0.0,
            'supplier': '',
            'location': '',
            'status': 'Active',
            'notes': 'Added via new order creation',
          };

          // Check if we're using an existing item or creating a new one
          bool success = false;
          if (orderItem.selectedItem != null) {
            // Using existing item - update stock quantity
            final currentStock = double.tryParse(orderItem.selectedItem!['currentStock'].toString()) ?? 0.0;
            final orderQuantity = double.tryParse(orderItem.quantityController.text) ?? 0.0;
            final newStock = currentStock - orderQuantity; // Subtract because it's a sale
            
            success = await _excelService.updateInventoryItemStock(
              orderItem.selectedItem!['id'].toString(), 
              newStock
            );
          } else {
            // Creating new item - add to inventory
            success = await _excelService.saveInventoryItemToExcel(itemData);
          }
          
          if (!success) {
            allSuccess = false;
            break;
          }
          
          // Add item name with quantity in the format "[item name] x [quantity]"
          final quantity = double.tryParse(orderItem.quantityController.text) ?? 1.0;
          final quantityString = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
          itemNames.add('${orderItem.itemNameController.text.trim()} x $quantityString');
        }

        if (allSuccess) {
          // Prepare and save order data
          final orderData = {
            'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
            'customerName': _customerNameController.text.trim(),
            'customerId': '',
            'orderDate': DateTime.now().toIso8601String(),
            'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'items': itemNames.join(', '),
            'totalAmount': _finalPrice,
            'paidAmount': _isPaid ? _finalPrice : 0.0, // Full amount if paid, 0 if credit
            'status': _isPaid ? 'PAID' : 'CREDIT', // Status based on payment toggle
            'priority': 'Normal',
            'assignedTo': '',
            'notes': 'Order created via app',
            'paymentMethod': _isPaid ? _selectedPaymentMethod : '', // Empty if credit
          };

          // Save order to Excel
          await _excelService.saveOrderToExcel(orderData);

          // Save individual sale details to sales tracking Excel
          await _saveSaleDetails(orderData);

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isPaid ? 'Order created successfully!' : 'Credit order created successfully!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${_orderItems.length} item(s) processed'),
                          if (!_isPaid) const Text('Payment status: Credit (Unpaid)', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: _isPaid ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
          // Clear form
          _clearForm();
        } else {
          throw Exception('Failed to save inventory data');
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Error creating order: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
  
  /// Save individual sale details to the sales tracking Excel file
  Future<void> _saveSaleDetails(Map<String, dynamic> orderData) async {
    try {
      // Convert order items to sale items format
      List<Map<String, dynamic>> saleItems = [];
      
      for (final orderItem in _orderItems) {
        final quantity = double.tryParse(orderItem.quantityController.text) ?? 0.0;
        final unitPrice = double.tryParse(orderItem.unitPriceController.text) ?? 0.0;
        
        if (orderItem.selectedItem != null && quantity > 0) {
          saleItems.add({
            'itemId': orderItem.selectedItem!['id']?.toString() ?? '',
            'itemName': orderItem.selectedItem!['name']?.toString() ?? '',
            'quantity': quantity.toString(),
            'sellingPrice': unitPrice.toString(),
            'wacCostPrice': orderItem.selectedItem!['unitCost']?.toString() ?? '0',
          });
        }
      }
      
      if (saleItems.isNotEmpty) {
        // Prepare sale data with customer information and payment status
        final saleData = {
          'saleId': orderData['orderId'],
          'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
          'customerName': orderData['customerName'] ?? 'Walk-in Customer',
          'items': saleItems,
          'vatAmount': _vatAmount,
          'subtotal': _subtotal,
          'finalPrice': _finalPrice,
          'isPaid': _isPaid,
          'paymentMethod': _isPaid ? _selectedPaymentMethod : '',
          'paymentStatus': _isPaid ? 'Paid' : 'Pending',
        };
        
        print('🔍 DEBUG NEW ORDER: Subtotal: $_subtotal, VAT Amount: $_vatAmount, Final Price: $_finalPrice');
        print('💳 DEBUG PAYMENT: Paid: $_isPaid, Method: ${_isPaid ? _selectedPaymentMethod : 'N/A'}');
        
        // Save to sales tracking Excel
        await _excelService.saveSaleToExcel(saleData);
        
        print('Sale details saved to tracking Excel: ${orderData['orderId']}');
      }
    } catch (e) {
      print('Error saving sale details: $e');
    }
  }
  
  void _clearForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerAddressController.clear();
    
    // Reset payment status to default
    _isPaid = true;
    _selectedPaymentMethod = 'Cash';
    
    // Clear all order items except the first one
    for (int i = _orderItems.length - 1; i > 0; i--) {
      _orderItems[i].dispose();
      _orderItems.removeAt(i);
    }
    
    // Clear the first order item
    _orderItems[0].itemNameController.clear();
    _orderItems[0].quantityController.clear();
    _orderItems[0].unitPriceController.clear();
    _orderItems[0].selectedItem = null;
    
    _updateCalculations();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Force navigation back to home screen
            context.go('/');
          },
          tooltip: 'Back to Home',
        ),
        title: const Text('New Sale'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Removed Reset Inventory File and Add Sample Data buttons for cleaner UI
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Clean margins on sides
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Comfortable internal padding
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Details Section
                    _buildSectionHeader('Customer Details'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[100]!.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _buildCustomerDetailsSection(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Item Details Section
                    _buildSectionHeader('Item Details'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Container()),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadInventoryItems,
                          tooltip: 'Refresh inventory items',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[100]!.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _buildItemDetailsSection(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Pricing Section
                    _buildSectionHeader('Pricing'),
                    const SizedBox(height: 12),
                    _buildPricingSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Summary Section
                    _buildSectionHeader('Order Summary'),
                    const SizedBox(height: 12),
                    _buildSummarySection(),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildCustomerDetailsSection() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer Name field
          Expanded(
            flex: 2,
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) => _handleKeyNavigation(event, _customerNameFocus),
              child: TextFormField(
                controller: _customerNameController,
                focusNode: _customerNameFocus,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'Enter customer name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  filled: true,
                  fillColor: Color(0xFFEEEEEE),
                ),
                style: const TextStyle(fontStyle: FontStyle.italic),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Customer name is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _focusNextField(_customerNameFocus),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Phone Number field
          Expanded(
            flex: 2,
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) => _handleKeyNavigation(event, _customerPhoneFocus),
              child: TextFormField(
                controller: _customerPhoneController,
                focusNode: _customerPhoneFocus,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  filled: true,
                  fillColor: Color(0xFFEEEEEE),
                ),
                style: const TextStyle(fontStyle: FontStyle.italic),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _focusNextField(_customerPhoneFocus),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Address field
          Expanded(
            flex: 2,
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) => _handleKeyNavigation(event, _customerAddressFocus),
              child: TextFormField(
                controller: _customerAddressController,
                focusNode: _customerAddressFocus,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'Enter customer address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  filled: true,
                  fillColor: Color(0xFFEEEEEE),
                ),
                style: const TextStyle(fontStyle: FontStyle.italic),
                onFieldSubmitted: (_) => _focusNextField(_customerAddressFocus),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemDetailsSection() {
    return Column(
      children: [
        // List of order items
        ...List.generate(_orderItems.length, (index) {
          return _buildOrderItemWidget(index);
        }),
        
        // Add item button
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addOrderItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Another Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOrderItemWidget(int index) {
    final orderItem = _orderItems[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[100]!.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with item number and remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_orderItems.length > 1)
                IconButton(
                  onPressed: () => _removeOrderItem(index),
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  tooltip: 'Remove item',
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // All fields in a single row aligned with container
          _isLoadingItems
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Item selection dropdown - equal width
                        Expanded(
                          flex: 2,
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (event) => _handleKeyNavigation(event, orderItem.itemDropdownFocus),
                            child: DropdownButtonFormField<Map<String, dynamic>>(
                            initialValue: orderItem.selectedItem,
                            focusNode: orderItem.itemDropdownFocus,
                            decoration: const InputDecoration(
                              labelText: 'Select Item *',
                              hintText: 'Choose item',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              filled: true,
                              fillColor: Color(0xFFEEEEEE),
                            ),
                          items: [
                            // Option to add new item
                            const DropdownMenuItem<Map<String, dynamic>>(
                              value: null,
                              child: Text(
                                '+ Add New Item',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // Existing inventory items
                            ..._inventoryItems.map((item) {
                              final name = item['name'].toString();
                              
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: item,
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, fontStyle: FontStyle.italic),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) => _onItemSelected(value, index),
                          validator: (value) {
                            if (orderItem.itemNameController.text.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          isExpanded: true,
                          menuMaxHeight: 200,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                          ),
                        ),
                      
                      const SizedBox(width: 12),
                      
                      // Manual item name (only if new item selected)
                      if (orderItem.selectedItem == null)
                        Expanded(
                          flex: 2,
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (event) => _handleKeyNavigation(event, orderItem.itemNameFocus),
                            child: TextFormField(
                              controller: orderItem.itemNameController,
                              focusNode: orderItem.itemNameFocus,
                              decoration: const InputDecoration(
                                labelText: 'Item Name *',
                                hintText: 'Enter name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.add_box, size: 20),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                filled: true,
                                fillColor: Color(0xFFEEEEEE),
                              ),
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _focusNextField(orderItem.itemNameFocus),
                            ),
                          ),
                        ),
                      
                      if (orderItem.selectedItem == null) const SizedBox(width: 12),
                      
                      // Quantity field
                      Expanded(
                        flex: 2,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleKeyNavigation(event, orderItem.quantityFocus),
                          child: TextFormField(
                            controller: orderItem.quantityController,
                            focusNode: orderItem.quantityFocus,
                            decoration: InputDecoration(
                              labelText: 'Qty *',
                              hintText: '0',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.numbers, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                              suffixText: orderItem.selectedItem != null 
                                  ? 'Max: ${(double.tryParse(orderItem.selectedItem!['currentStock'].toString()) ?? 0.0).toStringAsFixed(0)}'
                                  : null,
                            ),
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final quantity = double.tryParse(value);
                              if (quantity == null || quantity <= 0) {
                                return 'Invalid';
                              }
                              
                              // Check if quantity exceeds available stock for existing items
                              if (orderItem.selectedItem != null) {
                                final availableStock = double.tryParse(orderItem.selectedItem!['currentStock'].toString()) ?? 0.0;
                                if (quantity > availableStock) {
                                  return 'Exceeds stock';
                                }
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _focusNextField(orderItem.quantityFocus),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Unit Price field
                      Expanded(
                        flex: 2,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleKeyNavigation(event, orderItem.priceFocus),
                          child: TextFormField(
                            controller: orderItem.unitPriceController,
                            focusNode: orderItem.priceFocus,
                            decoration: const InputDecoration(
                              labelText: 'Price (BHD) *',
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              filled: true,
                              fillColor: Color(0xFFEEEEEE),
                            ),
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price < 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _showAddItemDialog(),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Item Total Display (equal width)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'BHD ${orderItem.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed VAT Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(
              color: Colors.green[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'VAT included in bill (10% Fixed)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '10%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal:', 'BHD ${_subtotal.toStringAsFixed(3)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'VAT Amount (10%):',
            'BHD ${_vatAmount.toStringAsFixed(3)}',
          ),
          const Divider(thickness: 2),
          _buildSummaryRow(
            'Final Total:',
            'BHD ${_finalPrice.toStringAsFixed(3)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal 
                ? Theme.of(context).colorScheme.primary 
                : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal 
                ? Theme.of(context).colorScheme.primary 
                : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text(
              'Clear Form',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}