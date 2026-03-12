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
  final List<String> _paymentMethods = ['Cash', 'Card', 'Benefit', 'Bank Transfer', 'Credit'];
  List<String> _banks = [];
  List<Map<String, dynamic>> _bankAccountObjects = []; // Full bank data for account number lookup
  String? _selectedBank;
  bool _isPaid = true; // Default to paid
  
  // Load bank accounts from Excel
  Future<void> _loadBankAccounts() async {
    try {
      final bankAccounts = await _excelService.loadBankAccountsFromExcel();
      setState(() {
        _bankAccountObjects = bankAccounts;
        _banks = bankAccounts.map((account) => account['bankName'].toString()).toList();
      });
    } catch (e) {
      debugPrint('Error loading bank accounts: $e');
    }
  }
  
  // Calculated values
  double _subtotal = 0.0;
  double _vatAmount = 0.0;
  double _finalPrice = 0.0;
  
  // Inventory data
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoadingItems = true;
  
  // Order items list
  final List<OrderItem> _orderItems = [OrderItem()];

  // Walk-in customer state
  bool _isWalkInCustomer = false;
  static const String _walkInName = 'Walk-in Customer';
  static const String _walkInPhone = '00000000';
  static const String _walkInAddress = 'N/A';
  
  // Focus node for global keyboard shortcuts
  final _globalFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
    
    // Add listeners to update calculations for each order item
    for (var orderItem in _orderItems) {
      orderItem.quantityController.addListener(_updateCalculations);
      orderItem.unitPriceController.addListener(_updateCalculations);
    }
    
    // Load inventory items
    _loadInventoryItems();
    
    // Request focus on global focus node to capture keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _globalFocusNode.requestFocus();
    });
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
    _globalFocusNode.dispose();
    
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

  void _setWalkInCustomer(bool isWalkIn) {
    setState(() {
      _isWalkInCustomer = isWalkIn;
      if (isWalkIn) {
        _customerNameController.text = _walkInName;
        _customerPhoneController.text = _walkInPhone;
        _customerAddressController.text = _walkInAddress;
      } else {
        _customerNameController.clear();
        _customerPhoneController.clear();
        _customerAddressController.clear();
      }
    });

    if (isWalkIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_orderItems.isNotEmpty) {
          _orderItems[0].itemDropdownFocus.requestFocus();
        }
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
    // ── Required field controllers ──────────────────────────────────────────
    final nameController        = TextEditingController();
    final categoryController    = TextEditingController();
    final unitController        = TextEditingController(text: 'pcs');
    final currentStockController= TextEditingController();
    final minStockController    = TextEditingController(text: '5');
    final maxStockController    = TextEditingController(text: '100');
    final costPriceController   = TextEditingController();
    final sellingPriceController= TextEditingController();

    // ── Optional field controllers ─────────────────────────────────────────
    final descriptionController = TextEditingController();
    final skuController         = TextEditingController();
    final barcodeController     = TextEditingController();
    final supplierController    = TextEditingController();
    final locationController    = TextEditingController();
    final notesController       = TextEditingController();

    // ── Status dropdown ────────────────────────────────────────────────────
    String selectedStatus = 'Active';

    // ── Focus nodes ────────────────────────────────────────────────────────
    final nameFocus         = FocusNode();
    final categoryFocus     = FocusNode();
    final unitFocus         = FocusNode();
    final currentStockFocus = FocusNode();
    final minStockFocus     = FocusNode();
    final maxStockFocus     = FocusNode();
    final costPriceFocus    = FocusNode();
    final sellingPriceFocus = FocusNode();
    final descriptionFocus  = FocusNode();
    final skuFocus          = FocusNode();
    final barcodeFocus      = FocusNode();
    final supplierFocus     = FocusNode();
    final locationFocus     = FocusNode();
    final notesFocus        = FocusNode();

    final formKey = GlobalKey<FormState>();

    // Helper to build a styled TextFormField matching the app's green theme
    Widget _field({
      required TextEditingController controller,
      required FocusNode focusNode,
      required String label,
      required IconData icon,
      FocusNode? nextFocus,
      bool required = false,
      bool numeric = false,
    }) {
      return SizedBox(
        height: 60,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            prefixIcon: Icon(icon, size: 20, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green[400]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            labelStyle: TextStyle(fontSize: 13, color: Colors.green[600]),
          ),
          onFieldSubmitted: (_) {
            if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
          },
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (numeric && double.tryParse(value.trim()) == null) return 'Invalid number';
                  return null;
                }
              : null,
        ),
      );
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.92,
                constraints: const BoxConstraints(maxWidth: 700, maxHeight: 680),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[300]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.15),
                      spreadRadius: 3,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Green gradient header ────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[600]!, Colors.green[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Inventory Item',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '* Required',
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Scrollable form body ─────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section: Basic Info
                              _sectionLabel('Basic Information'),
                              const SizedBox(height: 10),

                              // Row 1: Name | Category
                              Row(children: [
                                Expanded(child: _field(controller: nameController,     focusNode: nameFocus,     label: 'Name',     icon: Icons.inventory,         nextFocus: categoryFocus,    required: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: categoryController, focusNode: categoryFocus, label: 'Category', icon: Icons.category,          nextFocus: unitFocus,        required: true)),
                              ]),
                              const SizedBox(height: 12),

                              // Row 2: SKU (opt) | Barcode (opt) | Unit
                              Row(children: [
                                Expanded(child: _field(controller: skuController,      focusNode: skuFocus,      label: 'SKU',      icon: Icons.qr_code,           nextFocus: barcodeFocus)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: barcodeController,  focusNode: barcodeFocus,  label: 'Barcode',  icon: Icons.barcode_reader,    nextFocus: unitFocus)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: unitController,     focusNode: unitFocus,     label: 'Unit',     icon: Icons.straighten,        nextFocus: currentStockFocus, required: true)),
                              ]),
                              const SizedBox(height: 12),

                              // Row 3: Description (opt) – full width
                              SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: descriptionController,
                                  focusNode: descriptionFocus,
                                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Description (optional)',
                                    prefixIcon: const Icon(Icons.description, size: 20, color: Colors.green),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    labelStyle: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                  onFieldSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(currentStockFocus),
                                ),
                              ),

                              const SizedBox(height: 18),
                              // Section: Stock
                              _sectionLabel('Stock Details'),
                              const SizedBox(height: 10),

                              // Row 4: Current Stock | Min Stock | Max Stock
                              Row(children: [
                                Expanded(child: _field(controller: currentStockController, focusNode: currentStockFocus, label: 'Current Stock', icon: Icons.inventory_2,       nextFocus: minStockFocus,    required: true, numeric: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: minStockController,     focusNode: minStockFocus,     label: 'Min Stock',    icon: Icons.arrow_downward,    nextFocus: maxStockFocus,    required: true, numeric: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: maxStockController,     focusNode: maxStockFocus,     label: 'Max Stock',    icon: Icons.arrow_upward,      nextFocus: costPriceFocus,   required: true, numeric: true)),
                              ]),

                              const SizedBox(height: 18),
                              // Section: Pricing
                              _sectionLabel('Pricing'),
                              const SizedBox(height: 10),

                              // Row 5: Cost Price | Selling Price
                              Row(children: [
                                Expanded(child: _field(controller: costPriceController,    focusNode: costPriceFocus,    label: 'Cost Price',   icon: Icons.attach_money,      nextFocus: sellingPriceFocus, required: true, numeric: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: sellingPriceController, focusNode: sellingPriceFocus, label: 'Selling Price', icon: Icons.sell,             nextFocus: supplierFocus,    required: true, numeric: true)),
                              ]),

                              const SizedBox(height: 18),
                              // Section: Additional Details
                              _sectionLabel('Additional Details (Optional)'),
                              const SizedBox(height: 10),

                              // Row 6: Supplier (opt) | Location (opt) | Status
                              Row(children: [
                                Expanded(child: _field(controller: supplierController, focusNode: supplierFocus, label: 'Supplier', icon: Icons.business,      nextFocus: locationFocus)),
                                const SizedBox(width: 12),
                                Expanded(child: _field(controller: locationController, focusNode: locationFocus, label: 'Location', icon: Icons.location_on,   nextFocus: notesFocus)),
                                const SizedBox(width: 12),
                                // Status dropdown
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedStatus,
                                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                      decoration: InputDecoration(
                                        labelText: 'Status *',
                                        prefixIcon: const Icon(Icons.toggle_on, size: 20, color: Colors.green),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        labelStyle: TextStyle(fontSize: 13, color: Colors.green[600]),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'Active',       child: Text('Active')),
                                        DropdownMenuItem(value: 'Inactive',     child: Text('Inactive')),
                                        DropdownMenuItem(value: 'Discontinued', child: Text('Discontinued')),
                                      ],
                                      onChanged: (val) => setDialogState(() => selectedStatus = val ?? 'Active'),
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),

                              // Row 7: Notes (opt) – full width
                              SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: notesController,
                                  focusNode: notesFocus,
                                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    prefixIcon: const Icon(Icons.notes, size: 20, color: Colors.green),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    labelStyle: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Action buttons ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(top: BorderSide(color: Colors.green[100]!)),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.of(dialogContext).pop(null),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;

                              final itemData = {
                                'name':         nameController.text.trim(),
                                'category':     categoryController.text.trim(),
                                'description':  descriptionController.text.trim(),
                                'sku':          skuController.text.trim(),
                                'barcode':      barcodeController.text.trim(),
                                'unit':         unitController.text.trim(),
                                'currentStock': double.tryParse(currentStockController.text.trim()) ?? 0.0,
                                'minimumStock': double.tryParse(minStockController.text.trim()) ?? 0.0,
                                'maximumStock': double.tryParse(maxStockController.text.trim()) ?? 0.0,
                                'unitCost':     double.tryParse(costPriceController.text.trim()) ?? 0.0,
                                'sellingPrice': double.tryParse(sellingPriceController.text.trim()) ?? 0.0,
                                'supplier':     supplierController.text.trim(),
                                'location':     locationController.text.trim(),
                                'status':       selectedStatus,
                                'notes':        notesController.text.trim(),
                              };
                              Navigator.of(dialogContext).pop(itemData);
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // ── Dispose all controllers and focus nodes ──────────────────────────
    for (final c in [nameController, categoryController, unitController, currentStockController, minStockController, maxStockController, costPriceController, sellingPriceController, descriptionController, skuController, barcodeController, supplierController, locationController, notesController]) {
      c.dispose();
    }
    for (final f in [nameFocus, categoryFocus, unitFocus, currentStockFocus, minStockFocus, maxStockFocus, costPriceFocus, sellingPriceFocus, descriptionFocus, skuFocus, barcodeFocus, supplierFocus, locationFocus, notesFocus]) {
      f.dispose();
    }

    if (result != null) {
      await _addNewItemToInventory(result, orderItemIndex);
    } else {
      setState(() {
        _orderItems[orderItemIndex].selectedItem = null;
      });
    }
  }

  /// Small green section label used inside the dialog
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.green[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // Add the new item to inventory and then select it in the order
  Future<void> _addNewItemToInventory(Map<String, dynamic> itemData, int orderItemIndex) async {
    try {
      debugPrint('🔄 Adding new item to inventory: ${itemData['name']}');
      
      // Generate the next item ID
      final nextItemId = _generateNextItemId();
      debugPrint('📝 Generated item ID: $nextItemId');
      
      final now = DateTime.now();
      final fullItemData = {
        'id':           nextItemId,
        'name':         itemData['name']?.toString() ?? '',
        'category':     itemData['category']?.toString() ?? '',
        'description':  itemData['description']?.toString() ?? '',
        'sku':          itemData['sku']?.toString() ?? '',
        'barcode':      itemData['barcode']?.toString() ?? '',
        'unit':         itemData['unit']?.toString().isNotEmpty == true ? itemData['unit'].toString() : 'pcs',
        'currentStock': (itemData['currentStock'] as num?)?.toDouble() ?? 0.0,
        'minimumStock': (itemData['minimumStock'] as num?)?.toDouble() ?? 0.0,
        'maximumStock': (itemData['maximumStock'] as num?)?.toDouble() ?? 0.0,
        'unitCost':     (itemData['unitCost'] as num?)?.toDouble() ?? 0.0,
        'sellingPrice': (itemData['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        'supplier':     itemData['supplier']?.toString() ?? '',
        'location':     itemData['location']?.toString() ?? '',
        'status':       itemData['status']?.toString() ?? 'Active',
        'notes':        itemData['notes']?.toString() ?? '',
        'dateAdded':    now.toIso8601String().split('T')[0],
        'lastUpdated':  now.toIso8601String(),
      };

      debugPrint('💾 Saving item to Excel: $fullItemData');

      // Fix 3: Isolate the Excel save so a transaction sub-call failure
      // doesn't falsely report the whole operation as failed.
      bool success = false;
      try {
        // skipTransactionLog=true: adding a catalog item for sale is not a purchase expense.
        success = await _excelService.saveInventoryItemToExcel(fullItemData, skipTransactionLog: true);
      } catch (writeError) {
        debugPrint('❌ Excel write error: $writeError');
        success = false;
      }
      
      if (success) {
        // Reload inventory items to include the new item
        await _loadInventoryItems();
        
        // Fix 2: Safe lookup — if the item isn't found (e.g. stock filter
        // excluded it) inject fullItemData so the dropdown value is valid.
        Map<String, dynamic> newItem;
        final foundIndex = _inventoryItems.indexWhere((i) => i['id'] == nextItemId);
        if (foundIndex >= 0) {
          newItem = _inventoryItems[foundIndex];
        } else {
          newItem = fullItemData;
          setState(() {
            _inventoryItems = [fullItemData, ..._inventoryItems];
          });
        }
        
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
    String? tempSelectedBank = _selectedBank;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Payment Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text(
                      tempIsPaid ? 'Paid' : 'Credit',
                      style: TextStyle(
                        color: tempIsPaid ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: tempIsPaid,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    inactiveTrackColor: Colors.red[200],
                    onChanged: (value) {
                      setDialogState(() {
                        tempIsPaid = value;
                        if (!value) {
                          tempPaymentMethod = null;
                          tempSelectedBank = null;
                        }
                      });
                    },
                  ),
                  if (tempIsPaid)
                    DropdownButtonFormField<String>(
                      value: tempPaymentMethod,
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempPaymentMethod = value;
                          if (value != 'Bank Transfer') {
                            tempSelectedBank = null;
                          }
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                    ),
                  if (tempIsPaid && tempPaymentMethod == 'Bank Transfer')
                    DropdownButtonFormField<String>(
                      value: tempSelectedBank,
                      items: _banks.map((bank) {
                        return DropdownMenuItem(
                          value: bank,
                          child: Text(bank),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempSelectedBank = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Select Bank'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    if (tempIsPaid && tempPaymentMethod == 'Bank Transfer' && tempSelectedBank == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a bank for Bank Transfer.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'isPaid': tempIsPaid,
                      'paymentMethod': tempPaymentMethod,
                      'selectedBank': tempSelectedBank,
                    });
                  },
                  child: const Text('Confirm'),
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
        _selectedPaymentMethod = result['paymentMethod'];
        _selectedBank = result['selectedBank'];
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

          // Record bank transaction if payment was via Bank Transfer (Income)
          await _recordBankTransactionIfNeeded();

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
  
  /// Records an Income entry in the bank transactions ledger when payment is via Bank Transfer.
  Future<void> _recordBankTransactionIfNeeded() async {
    if (!_isPaid || _selectedPaymentMethod != 'Bank Transfer' || _selectedBank == null) return;
    try {
      final bankAccount = _bankAccountObjects.firstWhere(
        (a) => a['bankName'] == _selectedBank,
        orElse: () => {},
      );
      if (bankAccount.isEmpty) return;
      await _excelService.saveBankTransactionToExcel({
        'bankName': bankAccount['bankName'] ?? _selectedBank,
        'accountNumber': bankAccount['accountNumber'] ?? '',
        'transactionDate': DateTime.now().toIso8601String().split('T')[0],
        'transactionType': 'Income',
        'transactionAmount': _finalPrice,
      });
      debugPrint('✅ Bank transaction recorded: $_selectedBank | Income | BHD $_finalPrice');
    } catch (e) {
      debugPrint('⚠️ Failed to record bank transaction: $e');
    }
  }

  void _clearForm() {
    _isWalkInCustomer = false;
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
      body: KeyboardListener(
        focusNode: _globalFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyW) {
            _setWalkInCustomer(true);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Details Section
                    _buildSectionHeader('Customer Details'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[100]!.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: _buildCustomerDetailsSection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
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
                      padding: const EdgeInsets.all(10),
                      child: _buildItemDetailsSection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pricing Section
                    _buildSectionHeader('Pricing'),
                    const SizedBox(height: 8),
                    _buildPricingSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Summary Section
                    _buildSectionHeader('Order Summary'),
                    const SizedBox(height: 8),
                    _buildSummarySection(),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildCustomerDetailsSection() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Walk-in Customer',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Use default customer details and skip entry', style: TextStyle(fontSize: 12)),
          value: _isWalkInCustomer,
          onChanged: _setWalkInCustomer,
          activeColor: Colors.green,
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Name field
              Expanded(
                flex: 2,
                child: TextFormField(
                    controller: _customerNameController,
                    focusNode: _customerNameFocus,
                    enabled: !_isWalkInCustomer,
                    decoration: InputDecoration(
                      labelText: 'Customer Name *',
                      hintText: 'Enter customer name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      prefixIcon: const Icon(Icons.person, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                    ),
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    validator: (value) {
                      if (_isWalkInCustomer) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Customer name is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _focusNextField(_customerNameFocus),
                  ),
              ),
              const SizedBox(width: 8),
              // Phone Number field
              Expanded(
                flex: 2,
                child: TextFormField(
                    controller: _customerPhoneController,
                    focusNode: _customerPhoneFocus,
                    enabled: !_isWalkInCustomer,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'Enter phone number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      prefixIcon: const Icon(Icons.phone, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                    ),
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                    ],
                    validator: (value) {
                      if (_isWalkInCustomer) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _focusNextField(_customerPhoneFocus),
                  ),
              ),
              const SizedBox(width: 8),
              // Address field
              Expanded(
                flex: 2,
                child: TextFormField(
                    controller: _customerAddressController,
                    focusNode: _customerAddressFocus,
                    enabled: !_isWalkInCustomer,
                    decoration: InputDecoration(
                      labelText: 'Address (Optional)',
                      hintText: 'Enter customer address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      prefixIcon: const Icon(Icons.location_on, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                    ),
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    onFieldSubmitted: (_) => _focusNextField(_customerAddressFocus),
                  ),
              ),
            ],
          ),
        ),
      ],
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
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _addOrderItem,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Item', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOrderItemWidget(int index) {
    final orderItem = _orderItems[index];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _isLoadingItems
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
                    // Remove button (only if more than 1 item)
                    if (_orderItems.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconButton(
                          onPressed: () => _removeOrderItem(index),
                          icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                          tooltip: 'Remove item',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ),
                    
                    // Item selection dropdown
                    Expanded(
                      flex: 2,
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            // Fix 1: Use reactive `value` instead of `initialValue`
                            // so the dropdown updates when selectedItem changes via setState.
                            value: orderItem.selectedItem != null &&
                                    _inventoryItems.any((i) => i['id'] == orderItem.selectedItem!['id'])
                                ? _inventoryItems.firstWhere((i) => i['id'] == orderItem.selectedItem!['id'])
                                : orderItem.selectedItem,
                            focusNode: orderItem.itemDropdownFocus,
                            decoration: InputDecoration(
                              labelText: 'Select Item *',
                              hintText: 'Choose item',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              prefixIcon: const Icon(Icons.inventory, size: 16),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
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
                                  fontSize: 11,
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
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black),
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
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black),
                          ),
                        ),
                      
                      // Manual item name (only if new item selected)
                      if (orderItem.selectedItem == null)
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                              controller: orderItem.itemNameController,
                              focusNode: orderItem.itemNameFocus,
                              decoration: InputDecoration(
                                labelText: 'Item Name *',
                                hintText: 'Enter name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                prefixIcon: const Icon(Icons.add_box, size: 16),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFFEEEEEE),
                              ),
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _focusNextField(orderItem.itemNameFocus),
                            ),
                        ),
                      
                      // Quantity field
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                            controller: orderItem.quantityController,
                            focusNode: orderItem.quantityFocus,
                            decoration: InputDecoration(
                              labelText: 'Qty *',
                              hintText: '0',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              prefixIcon: const Icon(Icons.numbers, size: 16),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                              suffixText: orderItem.selectedItem != null 
                                  ? 'Max: ${(double.tryParse(orderItem.selectedItem!['currentStock'].toString()) ?? 0.0).toStringAsFixed(0)}'
                                  : null,
                            ),
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
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
                      
                      // Unit Price field
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                            controller: orderItem.unitPriceController,
                            focusNode: orderItem.priceFocus,
                            decoration: InputDecoration(
                              labelText: 'Price (BHD) *',
                              hintText: '0.00',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              prefixIcon: const Icon(Icons.attach_money, size: 16),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                            ),
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
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
                      
                      // Item Total Display (equal width)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
    );
  }
  
  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed VAT Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal:', 'BHD ${_subtotal.toStringAsFixed(3)}'),
          const SizedBox(height: 6),
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
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal 
                ? Theme.of(context).colorScheme.primary 
                : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text(
              'Clear Form',
              style: TextStyle(fontSize: 14),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create Order',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}