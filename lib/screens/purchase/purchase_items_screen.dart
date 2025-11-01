import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/routes/app_routes.dart';
import 'package:tailor_v3/services/excel_service.dart';
import '../inventory/inventory_management_screen.dart';
import 'package:tailor_v3/theme/colors.dart';

class PurchaseItemsScreen extends StatefulWidget {
  const PurchaseItemsScreen({super.key});

  @override
  State<PurchaseItemsScreen> createState() => _PurchaseItemsScreenState();
}

class _PurchaseItemsScreenState extends State<PurchaseItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExcelService _excelService = ExcelService();
  
  // Controllers
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();
  final _vendorSearchController = TextEditingController();
  
  // Global keys for dropdown controls
  final GlobalKey _itemDropdownKey = GlobalKey();
  
  // Search state
  List<Map<String, dynamic>> _filteredVendors = [];
  bool _showVendorSuggestions = false;
  int _selectedVendorIndex = -1;
  
  // Focus nodes for arrow key navigation
  final _vendorFocusNode = FocusNode();
  final _itemFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _costFocusNode = FocusNode();
  final _addButtonFocusNode = FocusNode();
  
  // List of focus nodes for navigation
  late List<FocusNode> _focusNodes;
  
  // Data lists
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _purchaseItems = [];
  
  // Selected values
  String? _selectedVendorId;
  String? _selectedItemId;
  DateTime _selectedDate = DateTime.now();
  bool _isPaid = true;
  bool _isLoading = false;
  bool _isAddingItem = false;
  
  // Purchase ID state
  String _purchaseId = '';
  bool _isLoadingPurchaseId = true;
  
  // VAT state - default to VAT inclusive
  bool _isVATInclusive = true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize focus nodes list for arrow key navigation
    // Order: Vendor → Item → Quantity → Cost → Add Button  
    _focusNodes = [
      _vendorFocusNode,      // 1. Vendor dropdown
      _itemFocusNode,        // 2. Item dropdown
      _quantityFocusNode,    // 3. Quantity field
      _costFocusNode,        // 4. Cost field
      _addButtonFocusNode,   // 5. Add Item button
    ];
    
    // Add focus listeners to auto-open dropdowns
    _vendorFocusNode.addListener(() {
      if (_vendorFocusNode.hasFocus) {
        // Focus gained on vendor dropdown
        // The dropdown will open automatically when clicked or Enter is pressed
      }
    });
    
    _itemFocusNode.addListener(() {
      if (_itemFocusNode.hasFocus) {
        // Focus gained on item dropdown  
        // The dropdown will open automatically when clicked or Enter is pressed
      }
    });
    
    // Generate sequential purchase ID
    _generateSequentialPurchaseId();
    
    _loadData();
    
    // Add listeners to update button state when fields change
    _quantityController.addListener(() {
      setState(() {});
    });
    _unitCostController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    _vendorSearchController.dispose();
    
    // Dispose focus nodes
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final vendors = await _excelService.loadVendorsFromExcel();
      final items = await _excelService.loadInventoryItemsFromExcel();
      
      setState(() {
        _vendors = vendors;
        _inventoryItems = items;
        _filteredVendors = vendors; // Initialize filtered list
      });
    } catch (e) {
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Filter vendors based on search text
  void _filterVendors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVendors = _vendors;
        _showVendorSuggestions = false;
        _selectedVendorIndex = -1;
      } else {
        _filteredVendors = _vendors.where((vendor) {
          final vendorName = vendor['vendorName']?.toString().toLowerCase() ?? '';
          return vendorName.contains(query.toLowerCase());
        }).toList();
        _showVendorSuggestions = _filteredVendors.isNotEmpty;
        _selectedVendorIndex = _filteredVendors.isNotEmpty ? 0 : -1; // Auto-select first match
      }
    });
  }

  // Helper method to check if all required fields are filled
  bool _areAllFieldsFilled() {
    return _selectedVendorId != null &&
           _selectedItemId != null &&
           _quantityController.text.trim().isNotEmpty &&
           _unitCostController.text.trim().isNotEmpty &&
           double.tryParse(_quantityController.text) != null &&
           double.tryParse(_quantityController.text)! > 0 &&
           double.tryParse(_unitCostController.text) != null &&
           double.tryParse(_unitCostController.text)! > 0;
  }

  // Arrow key navigation for form fields
  void _handleArrowKeyNavigation(LogicalKeyboardKey key) {
    final currentFocus = FocusScope.of(context).focusedChild;
    if (currentFocus == null) return;

    // Find current focus node index
    int currentIndex = -1;
    for (int i = 0; i < _focusNodes.length; i++) {
      if (_focusNodes[i].hasFocus) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex == -1) return;

    // Navigate based on arrow key
    if (key == LogicalKeyboardKey.arrowRight) {
      // Move to next field
      final nextIndex = (currentIndex + 1) % _focusNodes.length;
      FocusScope.of(context).requestFocus(_focusNodes[nextIndex]);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      // Move to previous field
      final prevIndex = (currentIndex - 1 + _focusNodes.length) % _focusNodes.length;
      FocusScope.of(context).requestFocus(_focusNodes[prevIndex]);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      // Move back to item field (useful after adding items)
      FocusScope.of(context).requestFocus(_itemFocusNode);
    }
  }

  // Generate sequential purchase ID starting from PUR_01001
  Future<void> _generateSequentialPurchaseId() async {
    try {
      setState(() {
        _isLoadingPurchaseId = true;
      });

      // Get the last purchase ID from Excel
      final lastPurchaseId = await _getLastPurchaseId();
      
      // Generate next sequential ID
      final nextSequentialNumber = _getNextSequentialNumber(lastPurchaseId);
      
      setState(() {
        _purchaseId = 'PUR_${nextSequentialNumber.toString().padLeft(5, '0')}';
        _isLoadingPurchaseId = false;
      });
    } catch (e) {
      // Fallback to starting number if error
      setState(() {
        _purchaseId = 'PUR_01001';
        _isLoadingPurchaseId = false;
      });
    }
  }

  Future<String> _getLastPurchaseId() async {
    try {
      // Get all purchase entries to find the last purchase ID
      final purchases = await _excelService.getAllPurchaseEntries();
      
      if (purchases.isEmpty) {
        return 'PUR_01000'; // Start from 01000 so next will be 01001
      }
      
      // Find the highest purchase ID
      String lastId = 'PUR_01000';
      int highestNumber = 1000;
      
      for (var purchase in purchases) {
        String purchaseId = purchase['purchaseId']?.toString() ?? '';
        if (purchaseId.startsWith('PUR_')) {
          String numberPart = purchaseId.substring(4); // Remove 'PUR_' prefix
          int? number = int.tryParse(numberPart);
          if (number != null && number > highestNumber) {
            highestNumber = number;
            lastId = purchaseId;
          }
        }
      }
      
      return lastId;
    } catch (e) {
      return 'PUR_01000'; // Default fallback
    }
  }

  int _getNextSequentialNumber(String lastPurchaseId) {
    try {
      if (lastPurchaseId.startsWith('PUR_')) {
        String numberPart = lastPurchaseId.substring(4); // Remove 'PUR_' prefix
        int? lastNumber = int.tryParse(numberPart);
        if (lastNumber != null) {
          return lastNumber + 1;
        }
      }
      return 1001; // Default starting number
    } catch (e) {
      return 1001; // Default starting number
    }
  }

  void _addItemToPurchase() async {
    if (_isAddingItem) return; // Prevent double-clicks
    
    setState(() {
      _isAddingItem = true;
    });

    try {
      if (_selectedItemId == null) {
        _showErrorSnackBar('Please select an item');
        return;
      }
      
      final quantity = double.tryParse(_quantityController.text);
      final unitCost = double.tryParse(_unitCostController.text);
      
      if (quantity == null || quantity <= 0) {
        _showErrorSnackBar('Please enter valid quantity');
        return;
      }
      
      if (unitCost == null || unitCost <= 0) {
        _showErrorSnackBar('Please enter valid unit cost');
        return;
      }
      
      final selectedItem = _inventoryItems.firstWhere(
        (item) => item['id'] == _selectedItemId,
        orElse: () => {},
      );
      
      if (selectedItem.isEmpty) {
        _showErrorSnackBar('Item not found');
        return;
      }
      
      final purchaseItem = {
        'itemId': _selectedItemId,
        'itemName': selectedItem['name'],
        'unit': selectedItem['unit'] ?? 'pcs',
        'quantity': quantity,
        'unitCost': unitCost,
        'totalCost': quantity * unitCost,
        'isVATInclusive': _isVATInclusive,
        'actualCost': _isVATInclusive ? unitCost / 1.10 : unitCost,
        'vatAmount': _isVATInclusive ? (unitCost - (unitCost / 1.10)) : 0.0,
      };
      
      // Add a small delay for better UX feedback
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() {
        _purchaseItems.add(purchaseItem);
        _selectedItemId = null;
        _quantityController.clear();
        _unitCostController.clear();
      });
      
      _showSuccessSnackBar('Item added to purchase list!');
      
      // Move focus back to item field for continuous entry with arrow key navigation
      Future.delayed(const Duration(milliseconds: 400), () {
        FocusScope.of(context).requestFocus(_itemFocusNode);
      });
    } catch (e) {
      _showErrorSnackBar('Error adding item: $e');
    } finally {
      setState(() {
        _isAddingItem = false;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  Future<void> _savePurchase() async {
    // Custom validation for saving purchase (not adding items)
    bool isValidForSave = true;
    String errorMessage = '';
    
    // Check if vendor is selected for the purchase
    if (_selectedVendorId == null) {
      isValidForSave = false;
      errorMessage = 'Please select a vendor for this purchase';
    }
    
    // Check if items have been added to purchase list
    if (_purchaseItems.isEmpty) {
      isValidForSave = false;
      errorMessage = 'Please add at least one item to the purchase list. Select an item, enter quantity and cost, then click "Add Item".';
    }
    
    if (!isValidForSave) {
      _showErrorSnackBar(errorMessage);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final selectedVendor = _vendors.firstWhere(
        (vendor) => vendor['vendorId'] == _selectedVendorId,
      );
      
      // Use the sequential purchase ID instead of random timestamp
      final purchaseId = _purchaseId;
      
      final purchaseData = {
        'id': purchaseId,
        'purchaseId': purchaseId, // Add this field for tracking
        'date': _selectedDate.toIso8601String().split('T')[0],
        'vendorId': _selectedVendorId,
        'vendorName': selectedVendor['vendorName'],
        'items': _purchaseItems,
        'notes': _notesController.text,
        'status': 'Completed',
        'paymentStatus': _isPaid ? 'Paid' : 'Credit',
        'isPaid': _isPaid,
      };
      
      // Save purchase details
      final success = await _excelService.savePurchaseToExcel(purchaseData);
      
      if (success) {
        // Update inventory quantities
        int successfulUpdates = 0;
        
        for (final item in _purchaseItems) {
          final updateSuccess = await _excelService.updateInventoryQuantity(
            item['itemId'],
            item['quantity'],
            itemName: item['itemName'],
            unit: item['unit'],
            unitCost: item['unitCost'],
          );
          
          if (updateSuccess) {
            successfulUpdates++;
          }
        }
        
        if (successfulUpdates == _purchaseItems.length) {
          _showSuccessSnackBar('Purchase saved successfully! Updated $successfulUpdates items in inventory.');
        } else {
          _showSuccessSnackBar('Purchase saved. Updated $successfulUpdates of ${_purchaseItems.length} items in inventory.');
        }
        
        _resetForm();
      } else {
        _showErrorSnackBar('Failed to save purchase');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving purchase: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedVendorId = null;
      _selectedItemId = null;
      _selectedDate = DateTime.now();
      _isPaid = true;
      _purchaseItems.clear();
      _notesController.clear();
      _quantityController.clear();
      _unitCostController.clear();
      _vendorSearchController.clear();
      _showVendorSuggestions = false;
      _selectedVendorIndex = -1;
    });
    
    // Generate new purchase ID for next purchase
    _generateSequentialPurchaseId();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            // Navigate back to home screen
            context.go(AppRoutes.home);
          },
          tooltip: 'Back to Home',
        ),
        title: const Text(
          'New Purchase Entry',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _handleArrowKeyNavigation(event.logicalKey);
                  }
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Vendor Details
                      _buildSectionCard(
                        title: 'Vendor Details',
                        icon: Icons.business,
                        child: Column(
                          children: [
                            _buildVendorDropdown(),
                            const SizedBox(height: 16),
                            if (_selectedVendorId != null) _buildVendorInfo(),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Section 2: Purchase Details
                    _buildSectionCard(
                      title: 'Purchase Details',
                      icon: Icons.shopping_cart,
                      child: Column(
                        children: [
                          // Display Purchase Date and ID in the header area
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      _isLoadingPurchaseId
                                          ? Row(
                                              children: [
                                                SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Generating ID...',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'ID: $_purchaseId',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Single Row: Item Selection, Quantity, Unit Cost
                          Row(
                            children: [
                              Expanded(flex: 3, child: _buildItemDropdown()),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: _buildQuantityField()),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: _buildUnitCostField()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Add Item button aligned to the right
                          Row(
                            children: [
                              const Spacer(),
                              Container(
                                width: 120,
                                height: 60,
                                child: Focus(
                                  focusNode: _addButtonFocusNode,
                                  child: KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: (KeyEvent event) {
                                      if (event is KeyDownEvent && 
                                          event.logicalKey == LogicalKeyboardKey.enter &&
                                          _areAllFieldsFilled() && !_isAddingItem) {
                                        _addItemToPurchase();
                                      }
                                    },
                                    child: ElevatedButton.icon(
                                      onPressed: _areAllFieldsFilled() && !_isAddingItem ? _addItemToPurchase : null,
                                      icon: _isAddingItem 
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.add, size: 18),
                                      label: Text(_isAddingItem ? 'Adding...' : 'Add Item'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Section 3: Items List
                    if (_purchaseItems.isNotEmpty)
                      _buildSectionCard(
                        title: 'Purchase Items',
                        icon: Icons.list,
                        child: _buildItemsList(),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Section 4: Inventory Updates (Display Only)
                    if (_purchaseItems.isNotEmpty)
                      _buildSectionCard(
                        title: 'Inventory Updates',
                        icon: Icons.update,
                        child: _buildInventoryUpdatesInfo(),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Section 5: Payment
                    _buildSectionCard(
                      title: 'Payment',
                      icon: Icons.payment,
                      child: _buildPaymentSection(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Section 6: Notes
                    _buildSectionCard(
                      title: 'Notes',
                      icon: Icons.note,
                      child: _buildNotesField(),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _savePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Purchase',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.textSecondary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildVendorDropdown() {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            child: Focus(
              focusNode: _vendorFocusNode,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent && _showVendorSuggestions && _filteredVendors.isNotEmpty) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      setState(() {
                        _selectedVendorIndex = (_selectedVendorIndex + 1) % _filteredVendors.length;
                      });
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      setState(() {
                        _selectedVendorIndex = (_selectedVendorIndex - 1 + _filteredVendors.length) % _filteredVendors.length;
                      });
                    } else if (event.logicalKey == LogicalKeyboardKey.enter && _selectedVendorIndex >= 0) {
                      final vendor = _filteredVendors[_selectedVendorIndex];
                      final vendorName = vendor['vendorName']?.toString() ?? 'Unknown Vendor';
                      setState(() {
                        _selectedVendorId = vendor['vendorId'];
                        _vendorSearchController.text = vendorName;
                        _showVendorSuggestions = false;
                        _selectedVendorIndex = -1;
                      });
                      // Auto-navigate to item field after vendor selection
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(_itemFocusNode);
                      });
                    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                      setState(() {
                        _showVendorSuggestions = false;
                        _selectedVendorIndex = -1;
                      });
                    }
                  }
                },
                child: TextFormField(
                  controller: _vendorSearchController,
                  decoration: InputDecoration(
                    labelText: 'Select Vendor *',
                    hintText: 'Type to search vendors...',
                    prefixIcon: const Icon(Icons.business, size: 20),
                    suffixIcon: _selectedVendorId != null 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedVendorId = null;
                              _vendorSearchController.clear();
                              _showVendorSuggestions = false;
                              _selectedVendorIndex = -1;
                            });
                          },
                        )
                      : const Icon(Icons.arrow_drop_down, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    labelStyle: const TextStyle(fontSize: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _selectedVendorIndex = -1; // Reset selection when typing
                    });
                    _filterVendors(value);
                  },
                  onFieldSubmitted: (value) {
                    // Auto-select first vendor suggestion if available and move to item field
                    if (_showVendorSuggestions && _filteredVendors.isNotEmpty) {
                      final selectedVendor = _filteredVendors[_selectedVendorIndex >= 0 ? _selectedVendorIndex : 0];
                      setState(() {
                        _selectedVendorId = selectedVendor['id'];
                        _vendorSearchController.text = selectedVendor['vendorName'];
                        _showVendorSuggestions = false;
                        _selectedVendorIndex = -1;
                      });
                      // Auto-navigate to item field after vendor selection
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(_itemFocusNode);
                      });
                    } else if (_selectedVendorId != null) {
                      // If vendor already selected, just move to item field
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(_itemFocusNode);
                      });
                    }
                  },
                  onTap: () {
                    if (_vendors.isNotEmpty) {
                      setState(() {
                        _filteredVendors = _vendors;
                        _showVendorSuggestions = true;
                        _selectedVendorIndex = -1;
                      });
                    }
                  },
                  validator: (value) {
                    if (_selectedVendorId == null) {
                      return 'Please select a vendor';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          // Suggestions dropdown
          if (_showVendorSuggestions && _filteredVendors.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredVendors.length,
                itemBuilder: (context, index) {
                  final vendor = _filteredVendors[index];
                  final vendorName = vendor['vendorName']?.toString() ?? 'Unknown Vendor';
                  
                  return Container(
                    color: index == _selectedVendorIndex 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    child: ListTile(
                      dense: true,
                      title: Text(
                        vendorName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: index == _selectedVendorIndex 
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedVendorId = vendor['vendorId'];
                          _vendorSearchController.text = vendorName;
                          _showVendorSuggestions = false;
                          _selectedVendorIndex = -1;
                        });
                        // Auto-navigate to item field after vendor selection
                        Future.delayed(const Duration(milliseconds: 100), () {
                          FocusScope.of(context).requestFocus(_itemFocusNode);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo() {
    final vendor = _vendors.firstWhere(
      (v) => v['vendorId'] == _selectedVendorId,
      orElse: () => {},
    );
    
    if (vendor.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vendor['vendorName']} (ID: ${vendor['vendorId']})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (vendor['phone']?.toString().isNotEmpty == true)
            Text('Phone: ${vendor['phone']}'),
          if (vendor['currentCredit'] != null)
            Text(
              'Current Credit: BHD ${vendor['currentCredit'].toStringAsFixed(2)}',
              style: TextStyle(
                color: vendor['currentCredit'] > 0 ? AppColors.accent1 : AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemDropdown() {
    return Container(
      height: 60,
      child: Focus(
        focusNode: _itemFocusNode,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                if (_selectedItemId != null && _selectedItemId != 'add_new_item') {
                  // Move to quantity field when Enter is pressed and item is selected
                  Future.delayed(const Duration(milliseconds: 100), () {
                    FocusScope.of(context).requestFocus(_quantityFocusNode);
                  });
                }
              } else {
                _handleArrowKeyNavigation(event.logicalKey);
              }
            }
          },
          child: DropdownButtonFormField<String>(
            key: _itemDropdownKey,
            value: _selectedItemId,
            decoration: InputDecoration(
              labelText: 'Item Name *',
              prefixIcon: const Icon(Icons.inventory, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: const TextStyle(fontSize: 14),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            autofocus: false,
            onTap: () {
              // Ensure dropdown opens when tapped or focused
            },
          items: [
            ..._inventoryItems.map((item) {
              return DropdownMenuItem<String>(
                value: item['id'],
                child: Text(item['name'], style: const TextStyle(fontSize: 14, color: Colors.black)),
              );
            }).toList(),
            const DropdownMenuItem<String>(
              value: 'add_new_item',
              child: Text('➕ Add New Item', style: TextStyle(fontSize: 14, color: Colors.black)),
            ),
          ],
          onChanged: (value) {
            if (value == 'add_new_item') {
              _openAddNewItemDialog();
            } else {
              setState(() {
                _selectedItemId = value;
              });
              // Auto-navigate to quantity field after item selection
              Future.delayed(const Duration(milliseconds: 100), () {
                FocusScope.of(context).requestFocus(_quantityFocusNode);
              });
            }
          },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
        isExpanded: true,
        ),
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return Container(
      height: 60,
      child: TextFormField(
        controller: _quantityController,
        focusNode: _quantityFocusNode,
        decoration: InputDecoration(
          labelText: 'Quantity *',
          prefixIcon: const Icon(Icons.numbers, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(fontSize: 14),
        ),
        style: const TextStyle(fontSize: 14),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onFieldSubmitted: (value) {
          // Move to cost field when Enter is pressed
          FocusScope.of(context).requestFocus(_costFocusNode);
        },
        onChanged: (value) {
          // Remove the calculation since we removed _itemTotal
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          final qty = double.tryParse(value.trim());
          if (qty == null || qty <= 0) {
            return 'Invalid';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _openAddNewItemDialog() async {
    // Open the existing AddNewMaterialDialog from inventory screen and await the created item
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AddNewMaterialDialog(
          excelService: _excelService,
          onMaterialAdded: () async {
            // no-op; we'll reload after dialog returns
          },
          existingCategories: _inventoryItems.map((e) => e['category']?.toString() ?? '').toList(),
        ),
      );

      if (result != null) {
        // A new item was created. Reload inventory items and select the new one.
        final items = await _excelService.loadInventoryItemsFromExcel();
        setState(() {
          _inventoryItems = items;
          _selectedItemId = result['id']?.toString();
          
          // Auto-populate the unit cost field with the cost price from the new item
          final unitCost = result['costPrice']?.toString() ?? result['unitCost']?.toString() ?? '0.0';
          _unitCostController.text = unitCost;
        });
        _showSuccessSnackBar('New item "${result['name']}" added and selected');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add new item: $e');
    }
  }

  Widget _buildUnitCostField() {
    return Container(
      height: 60,
      child: TextFormField(
        controller: _unitCostController,
        focusNode: _costFocusNode,
        decoration: InputDecoration(
          labelText: 'Cost Price *',
          prefixIcon: const Icon(Icons.attach_money, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(fontSize: 14),
        ),
        style: const TextStyle(fontSize: 14),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onFieldSubmitted: (value) {
          // Directly add item to cart when Enter is pressed on cost field
          if (_areAllFieldsFilled() && !_isAddingItem) {
            _addItemToPurchase();
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          final cost = double.tryParse(value);
          if (cost == null || cost <= 0) {
            return 'Invalid';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildItemsList() {
    double grandTotal = _purchaseItems.fold(0.0, (sum, item) => sum + item['totalCost']);
    
    return Column(
      children: [
        ...List.generate(_purchaseItems.length, (index) {
          final item = _purchaseItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.background.withOpacity(0.5),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                '${item['itemName']}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qty: ${item['quantity']} ${item['unit']} × BHD ${item['unitCost'].toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  // Only show VAT information when global VAT toggle is ON
                  if (_isVATInclusive) ...[
                    if (item['isVATInclusive'] == true)
                      Text(
                        'VAT Inclusive (Actual: BHD ${item['actualCost'].toStringAsFixed(2)}, VAT: BHD ${item['vatAmount'].toStringAsFixed(2)})',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'VAT Exclusive',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BHD ${item['totalCost'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _removeItem(index),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_purchaseItems.isNotEmpty) ...[
          const Divider(thickness: 2, color: AppColors.primary),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'BHD ${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // VAT Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isVATInclusive ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isVATInclusive ? Colors.green[300]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isVATInclusive ? Icons.check_circle : Icons.cancel,
                  color: _isVATInclusive ? Colors.green[600] : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAT Inclusive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isVATInclusive ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                      Text(
                        _isVATInclusive 
                            ? 'Cost prices include 10% VAT' 
                            : 'Cost prices exclude VAT',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isVATInclusive ? Colors.green[600] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isVATInclusive = !_isVATInclusive;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: _isVATInclusive ? Colors.green : Colors.grey[400],
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: _isVATInclusive 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft,
                      child: Container(
                        width: 21,
                        height: 21,
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInventoryUpdatesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent1.withOpacity(0.1),
        border: Border.all(color: AppColors.accent1.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: AppColors.accent1),
              SizedBox(width: 8),
              Text(
                'Inventory Updates (After Save)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Current Stock will be updated with new quantities',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const Text(
            '• Unit Cost will be recalculated using Weighted Average Cost',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            '• Last Updated will be set to ${DateTime.now().toIso8601String().split('T')[0]}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            'Payment Status',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            _isPaid ? 'Paid' : 'Credit',
            style: TextStyle(
              color: _isPaid ? AppColors.primary : AppColors.accent1,
              fontWeight: FontWeight.bold,
            ),
          ),
          value: _isPaid,
          onChanged: (value) {
            setState(() {
              _isPaid = value;
            });
          },
          activeColor: AppColors.primary,
        ),
        if (!_isPaid)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent1.withOpacity(0.1),
              border: Border.all(color: AppColors.accent1.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppColors.accent1),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This purchase will be added to vendor\'s credit balance.',
                    style: TextStyle(color: AppColors.accent1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Additional Notes',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.note, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      maxLines: 3,
      maxLength: 500,
    );
  }
}
