import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/excel_service.dart';

class InventoryItemsScreen extends StatefulWidget {
  const InventoryItemsScreen({super.key});

  @override
  State<InventoryItemsScreen> createState() => _InventoryItemsScreenState();
}

class _InventoryItemsScreenState extends State<InventoryItemsScreen> {
  final ExcelService _excelService = ExcelService.instance;
  final _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  bool _showAddItemForm = false;
  String _searchQuery = '';
  
  // Removed VAT functionality as per requirements
  
  // Form controllers
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _searchController = TextEditingController();
  
  // Focus nodes for arrow key navigation
  final _nameFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  final _stockFocusNode = FocusNode();
  final _unitCostFocusNode = FocusNode();
  final _sellingPriceFocusNode = FocusNode();
  final _addButtonFocusNode = FocusNode();
  
  // List of focus nodes for navigation
  late List<FocusNode> _focusNodes;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize focus nodes list for arrow key navigation
    // Order: Name → Category → Stock → Unit Cost → Selling Price → Add Button
    _focusNodes = [
      _nameFocusNode,         // 1. Item Name
      _categoryFocusNode,     // 2. Category
      _stockFocusNode,        // 3. Current Stock
      _unitCostFocusNode,     // 4. Unit Cost
      _sellingPriceFocusNode, // 5. Selling Price
      _addButtonFocusNode,    // 6. Add Item button
    ];
    
    _loadInventoryData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _currentStockController.dispose();
    _unitCostController.dispose();
    _sellingPriceController.dispose();
    _searchController.dispose();
    
    // Dispose focus nodes
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    
    super.dispose();
  }

  // Generate the next sequential item ID starting from ITM-01000
  String _generateNextItemId() {
    if (_inventoryItems.isEmpty) {
      return 'ITM-01000'; // First item starts at ITM-01000
    }
    
    // Find the highest existing item ID
    int maxNumber = 999; // Starting number minus 1
    
    for (var item in _inventoryItems) {
      final itemId = item['id']?.toString() ?? '';
      if (itemId.startsWith('ITM-')) {
        // Extract the number part after 'ITM-'
        final numberPart = itemId.substring(4);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    // Return the next ID
    final nextNumber = maxNumber + 1;
    return 'ITM-${nextNumber.toString().padLeft(5, '0')}';
  }

  Future<void> _loadInventoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final inventoryItems = await _excelService.loadInventoryItemsFromExcel();
      
      print('=== INVENTORY SCREEN DEBUG ===');
      print('Loaded ${inventoryItems.length} items');
      for (var item in inventoryItems) {
        print('Item: ${item['name']} (ID: ${item['id']}) - Stock: ${item['currentStock']} - Status: ${item['status']}');
        print('  Full item data: $item');
      }
      print('==============================');
      
      setState(() {
        _inventoryItems = inventoryItems;
        _filteredItems = inventoryItems; // Initialize filtered items with all items
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Generate the next item ID
      final nextItemId = _generateNextItemId();
      
      final itemData = {
        'id': nextItemId,  // Add predefined ID
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'currentStock': double.tryParse(_currentStockController.text) ?? 0.0,
        'unitCost': double.tryParse(_unitCostController.text) ?? 0.0,
        'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0.0,
        'unit': 'pcs',
        'minimumStock': 5.0,
        'maximumStock': 100.0,
        'status': 'Active',
        'description': '', // Add missing fields
        'sku': '',
        'barcode': '',
        'supplier': '',
        'location': '',
        'notes': '',
        'dateAdded': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final success = await _excelService.saveInventoryItemToExcel(itemData);
      
      if (success) {
        _clearForm();
        setState(() {
          _showAddItemForm = false;
        });
        await _loadInventoryData();
        // Re-apply current search filter
        if (_searchQuery.isNotEmpty) {
          _filterItems(_searchQuery);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Text('Item added with ID: $nextItemId'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add item')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
    }
  }

  void _clearForm() {
    _nameController.clear();
    _categoryController.clear();
    _currentStockController.clear();
    _unitCostController.clear();
    _sellingPriceController.clear();
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _inventoryItems;
      } else {
        _filteredItems = _inventoryItems.where((item) {
          final name = item['name'].toString().toLowerCase();
          final category = item['category'].toString().toLowerCase();
          final description = item['description']?.toString().toLowerCase() ?? '';
          final supplier = item['supplier']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return name.contains(searchLower) ||
                 category.contains(searchLower) ||
                 description.contains(searchLower) ||
                 supplier.contains(searchLower);
        }).toList();
      }
      
      // Sort items alphabetically by name for grouping
      _filteredItems.sort((a, b) => 
        (a['name']?.toString() ?? '').toLowerCase().compareTo(
          (b['name']?.toString() ?? '').toLowerCase()
        )
      );
    });
  }

  // Helper method to group items by first letter
  Map<String, List<Map<String, dynamic>>> _groupItemsByAlphabet() {
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};
    
    for (var item in _filteredItems) {
      if (item['status'] != 'Active') continue;
      
      final itemName = item['name']?.toString() ?? '';
      if (itemName.isEmpty) continue;
      
      final firstLetter = itemName[0].toUpperCase();
      if (!groupedItems.containsKey(firstLetter)) {
        groupedItems[firstLetter] = [];
      }
      groupedItems[firstLetter]!.add(item);
    }
    
    // Sort the groups by alphabet
    final sortedGroups = Map.fromEntries(
      groupedItems.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    return sortedGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Items'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/stock-purchase-history'),
            tooltip: 'Purchase History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventoryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInventoryData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_inventoryItems.where((item) => item['status'] == 'Active').length}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const Text('Total Items'),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAddItemForm = !_showAddItemForm;
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _filterItems,
                              decoration: InputDecoration(
                                hintText: 'Search items by name, category, description, or supplier...',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterItems('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Add Item Form
                    if (_showAddItemForm) ...[
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green[600]!, Colors.green[700]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Add New Item',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        'Form',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Row 1: Item Name, Category, Current Stock
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(),
                                          onKeyEvent: (KeyEvent event) {
                                            if (event is KeyDownEvent) {
                                              _handleArrowKeyNavigation(event.logicalKey);
                                            }
                                          },
                                          child: TextFormField(
                                            controller: _nameController,
                                            focusNode: _nameFocusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Item Name *',
                                              prefixIcon: const Icon(Icons.inventory, size: 20, color: Colors.green),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 14, color: Colors.green[600]),
                                            ),
                                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                            onFieldSubmitted: (value) {
                                              // Move to category field when Enter is pressed
                                              FocusScope.of(context).requestFocus(_categoryFocusNode);
                                            },
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(),
                                          onKeyEvent: (KeyEvent event) {
                                            if (event is KeyDownEvent) {
                                              _handleArrowKeyNavigation(event.logicalKey);
                                            }
                                          },
                                          child: TextFormField(
                                            controller: _categoryController,
                                            focusNode: _categoryFocusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Category *',
                                              prefixIcon: const Icon(Icons.category, size: 20, color: Colors.green),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 14, color: Colors.green[600]),
                                            ),
                                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                            onFieldSubmitted: (value) {
                                              // Move to stock field when Enter is pressed
                                              FocusScope.of(context).requestFocus(_stockFocusNode);
                                            },
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(),
                                          onKeyEvent: (KeyEvent event) {
                                            if (event is KeyDownEvent) {
                                              _handleArrowKeyNavigation(event.logicalKey);
                                            }
                                          },
                                          child: TextFormField(
                                            controller: _currentStockController,
                                            focusNode: _stockFocusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Stock *',
                                              prefixIcon: const Icon(Icons.inventory_2, size: 20, color: Colors.green),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 14, color: Colors.green[600]),
                                            ),
                                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                            keyboardType: TextInputType.number,
                                            onFieldSubmitted: (value) {
                                              // Move to unit cost field when Enter is pressed
                                              FocusScope.of(context).requestFocus(_unitCostFocusNode);
                                            },
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Required';
                                              }
                                              if (double.tryParse(value) == null) {
                                                return 'Invalid';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Row 2: Unit Cost, Selling Price, VAT Toggle
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(),
                                          onKeyEvent: (KeyEvent event) {
                                            if (event is KeyDownEvent) {
                                              _handleArrowKeyNavigation(event.logicalKey);
                                            }
                                          },
                                          child: TextFormField(
                                            controller: _unitCostController,
                                            focusNode: _unitCostFocusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Unit Cost *',
                                              prefixIcon: const Icon(Icons.attach_money, size: 20, color: Colors.green),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 14, color: Colors.green[600]),
                                            ),
                                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                            keyboardType: TextInputType.number,
                                            onFieldSubmitted: (value) {
                                              // Move to selling price field when Enter is pressed
                                              FocusScope.of(context).requestFocus(_sellingPriceFocusNode);
                                            },
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Required';
                                              }
                                              if (double.tryParse(value) == null) {
                                                return 'Invalid';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(),
                                          onKeyEvent: (KeyEvent event) {
                                            if (event is KeyDownEvent) {
                                              _handleArrowKeyNavigation(event.logicalKey);
                                            }
                                          },
                                          child: TextFormField(
                                            controller: _sellingPriceController,
                                            focusNode: _sellingPriceFocusNode,
                                            decoration: InputDecoration(
                                              labelText: 'Selling Price *',
                                              prefixIcon: const Icon(Icons.sell, size: 20, color: Colors.green),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 14, color: Colors.green[600]),
                                            ),
                                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black),
                                            keyboardType: TextInputType.number,
                                            onFieldSubmitted: (value) {
                                              // Move to add button when Enter is pressed
                                              FocusScope.of(context).requestFocus(_addButtonFocusNode);
                                            },
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Required';
                                              }
                                              if (double.tryParse(value) == null) {
                                                return 'Invalid';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Focus(
                                      focusNode: _addButtonFocusNode,
                                      child: KeyboardListener(
                                        focusNode: FocusNode(),
                                        onKeyEvent: (KeyEvent event) {
                                          if (event is KeyDownEvent) {
                                            if (event.logicalKey == LogicalKeyboardKey.enter) {
                                              _addItem();
                                            } else {
                                              _handleArrowKeyNavigation(event.logicalKey);
                                            }
                                          }
                                        },
                                        child: ElevatedButton.icon(
                                          onPressed: _addItem,
                                          icon: const Icon(Icons.save, size: 18),
                                          label: const Text('Save Item'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _showAddItemForm = false;
                                        });
                                        _clearForm();
                                      },
                                      icon: const Icon(Icons.cancel, size: 18),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[700],
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
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
                    ],
                    
                    // Items List
                    Expanded(
                      child: _inventoryItems.isEmpty
                          ? const Center(
                              child: Text('No items found. Add some items to get started!'),
                            )
                          : _filteredItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No items found for "$_searchQuery"',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try searching with different keywords',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_searchQuery.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Found ${_filteredItems.where((item) => item['status'] == 'Active').length} item(s) for "$_searchQuery"',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                // Header Row
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    border: Border.all(color: Colors.green[200]!),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      // Qty header
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          'Qty',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // Item Name header
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Item Name',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 8),
                                      
                                      // Category header
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Category',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 8),
                                      
                                      // Price header
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Price',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 8),
                                      
                                      // Cost header
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Cost',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 24), // Space for menu icon
                                    ],
                                  ),
                                ),
                                
                                // Items List
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final groupedItems = _groupItemsByAlphabet();
                                      
                                      if (groupedItems.isEmpty) {
                                        return const Center(
                                          child: Text('No active items found'),
                                        );
                                      }
                                      
                                      return ListView.builder(
                                        itemCount: groupedItems.length,
                                        itemBuilder: (context, groupIndex) {
                                          final letter = groupedItems.keys.elementAt(groupIndex);
                                          final itemsInGroup = groupedItems[letter]!;
                                          
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Alphabet Header
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                child: Text(
                                                  letter,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              
                                              // Container for items in this alphabet group
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[25], // Very light green background
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.green[100]!, // Subtle green border
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: itemsInGroup.map((item) {
                                                    final currentStock = (item['currentStock'] ?? 0.0) as double;
                                                    final minimumStock = (item['minimumStock'] ?? 0.0) as double;
                                                    final unitCost = (item['unitCost'] ?? 0.0) as double;
                                                    final sellingPrice = (item['sellingPrice'] ?? 0.0) as double;
                                                    final category = item['category']?.toString() ?? 'N/A';
                                                    final isLowStock = currentStock <= minimumStock;
                                                
                                                // Check if item was recently updated (within last 24 hours)
                                                final lastUpdatedStr = item['lastUpdated']?.toString();
                                                bool isRecentlyUpdated = false;
                                                if (lastUpdatedStr != null) {
                                                  try {
                                                    final lastUpdated = DateTime.parse(lastUpdatedStr);
                                                    final now = DateTime.now();
                                                    final difference = now.difference(lastUpdated);
                                                    isRecentlyUpdated = difference.inHours < 24;
                                                  } catch (e) {
                                                    isRecentlyUpdated = false;
                                                  }
                                                }
                                                
                                                return Container(
                                                  margin: const EdgeInsets.all(0), // Remove margin since it's inside group container
                                                  decoration: BoxDecoration(
                                                    color: isRecentlyUpdated ? Colors.blue[50] : Colors.white,
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey[200]!,
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () => _showItemDetails(item),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                      child: Row(
                                                        children: [
                                                          // Quantity Badge
                                                          Container(
                                                            width: 50,
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isLowStock 
                                                                  ? Colors.red[100] 
                                                                  : currentStock > 0 
                                                                      ? Colors.green[100] 
                                                                      : Colors.orange[100],
                                                              borderRadius: BorderRadius.circular(12),
                                                              border: Border.all(
                                                                color: isLowStock 
                                                                    ? Colors.red[300]! 
                                                                    : currentStock > 0 
                                                                        ? Colors.green[300]! 
                                                                        : Colors.orange[300]!,
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              '[${currentStock.toInt()}]',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                                color: isLowStock 
                                                                    ? Colors.red[700] 
                                                                    : currentStock > 0 
                                                                        ? Colors.green[700] 
                                                                        : Colors.orange[700],
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                          
                                                          const SizedBox(width: 12),
                                                          
                                                          // Item Name (flexible, takes available space)
                                                          Expanded(
                                                            flex: 3,
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  item['name'] ?? 'Unknown Item',
                                                                  style: const TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.black87,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                if (isLowStock)
                                                                  Text(
                                                                    'Low Stock',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      color: Colors.red[600],
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                if (isRecentlyUpdated)
                                                                  Text(
                                                                    'Recently Updated',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      color: Colors.blue[600],
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          
                                                          const SizedBox(width: 8),
                                                          
                                                          // Category
                                                          Expanded(
                                                            flex: 2,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.blue[50],
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                category,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.blue[700],
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ),
                                                          ),
                                                          
                                                          const SizedBox(width: 8),
                                                          
                                                          // Selling Price
                                                          Expanded(
                                                            flex: 2,
                                                            child: Text(
                                                              'BHD ${sellingPrice.toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.green[700],
                                                              ),
                                                              textAlign: TextAlign.right,
                                                            ),
                                                          ),
                                                          
                                                          const SizedBox(width: 8),
                                                          
                                                          // Cost Price
                                                          Expanded(
                                                            flex: 2,
                                                            child: Text(
                                                              'Cost: BHD ${unitCost.toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.grey[600],
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              textAlign: TextAlign.right,
                                                            ),
                                                          ),
                                                          
                                                          // Actions Menu
                                                          const SizedBox(width: 8),
                                                          Icon(
                                                            Icons.more_vert,
                                                            size: 16,
                                                            color: Colors.grey[400],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                                  }).toList(),
                                                ),
                                              ),
                                              
                                              // Add some spacing after each group
                                              const SizedBox(height: 8),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final currentStock = int.tryParse(item['currentStock']?.toString() ?? '0') ?? 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FFF8)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Item Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                _getStockStatusIcon(currentStock),
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStockStatusText(currentStock),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildModernSection(
                        'Basic Information',
                        Icons.info_outline,
                        [
                          _buildModernDetailRow('ID', item['id']?.toString() ?? 'N/A', Icons.tag),
                          _buildModernDetailRow('Category', item['category']?.toString() ?? 'N/A', Icons.category),
                          _buildModernDetailRow('Status', item['status']?.toString() ?? 'N/A', Icons.check_circle),
                          _buildModernDetailRow('Date Added', item['dateAdded']?.toString() ?? 'N/A', Icons.calendar_today),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pricing Section
                      _buildModernSection(
                        'Pricing',
                        Icons.monetization_on,
                        [
                          _buildModernDetailRow('Unit Cost', 'BHD ${item['unitCost']?.toStringAsFixed(3) ?? '0.000'}', Icons.shopping_cart),
                          _buildModernDetailRow('Selling Price', 'BHD ${item['sellingPrice']?.toStringAsFixed(3) ?? '0.000'}', Icons.sell),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Stock Information Section
                      _buildModernSection(
                        'Stock Information',
                        Icons.inventory,
                        [
                          _buildModernDetailRow('Current Stock', '${item['currentStock'] ?? '0'} ${item['unit'] ?? ''}', Icons.inventory_2, 
                            valueColor: _getStockStatusColor(currentStock)),
                          _buildModernDetailRow('Minimum Stock', '${item['minimumStock'] ?? '0'} ${item['unit'] ?? ''}', Icons.warning),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Location & Supplier Section
                      _buildModernSection(
                        'Additional Details',
                        Icons.business,
                        [
                          _buildModernDetailRow('Supplier', item['supplier']?.toString() ?? 'N/A', Icons.business),
                          _buildModernDetailRow('Location', item['location']?.toString() ?? 'N/A', Icons.location_on),
                        ],
                      ),
                      
                      if (item['description']?.toString().isNotEmpty == true) ...[
                        const SizedBox(height: 20),
                        _buildModernSection(
                          'Description',
                          Icons.description,
                          [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              child: Text(
                                item['description']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF757575)),
                          foregroundColor: const Color(0xFF757575),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showEditItemDialog(item);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDeleteConfirmationDialog(item);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFE57373),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    final editFormKey = GlobalKey<FormState>();
    
    // Controllers for editing
    final editNameController = TextEditingController(text: item['name']?.toString() ?? '');
    final editCategoryController = TextEditingController(text: item['category']?.toString() ?? '');
    final editDescriptionController = TextEditingController(text: item['description']?.toString() ?? '');
    final editCurrentStockController = TextEditingController(text: item['currentStock']?.toString() ?? '0');
    final editMinStockController = TextEditingController(text: item['minimumStock']?.toString() ?? '0');
    final editMaxStockController = TextEditingController(text: item['maximumStock']?.toString() ?? '0');
    final editUnitCostController = TextEditingController(text: item['unitCost']?.toString() ?? '0');
    final editSellingPriceController = TextEditingController(text: item['sellingPrice']?.toString() ?? '0');
    final editSupplierController = TextEditingController(text: item['supplier']?.toString() ?? '');
    final editLocationController = TextEditingController(text: item['location']?.toString() ?? '');
    final editNotesController = TextEditingController(text: item['notes']?.toString() ?? '');
    
    // VAT inclusive state for edit dialog
    bool isEditCostVATInclusive = true; // Default to VAT inclusive

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setEditDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8FFF8)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit ${item['name'] ?? 'Item'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Update item information',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: editFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildModernEditSection(
                            'Basic Information',
                            Icons.info_outline,
                            [
                              _buildModernFormField(
                                controller: editNameController,
                                label: 'Item Name *',
                                icon: Icons.inventory,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Item name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editCategoryController,
                                      label: 'Category *',
                                      icon: Icons.category,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Category is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editSupplierController,
                                      label: 'Supplier',
                                      icon: Icons.business,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildModernFormField(
                                controller: editDescriptionController,
                                label: 'Description',
                                icon: Icons.description,
                                maxLines: 2,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Stock Information Section
                          _buildModernEditSection(
                            'Stock Information',
                            Icons.inventory,
                            [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editCurrentStockController,
                                      label: 'Current Stock *',
                                      icon: Icons.inventory_2,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Current stock is required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editMinStockController,
                                      label: 'Minimum Stock',
                                      icon: Icons.warning,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editMaxStockController,
                                      label: 'Maximum Stock',
                                      icon: Icons.trending_up,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editLocationController,
                                      label: 'Location',
                                      icon: Icons.location_on,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Pricing Information Section
                          _buildModernEditSection(
                            'Pricing Information',
                            Icons.monetization_on,
                            [
                              // VAT Toggle
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isEditCostVATInclusive ? const Color(0xFFF1F8E9) : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isEditCostVATInclusive ? const Color(0xFF4CAF50) : const Color(0xFFBDBDBD),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.percent,
                                      color: isEditCostVATInclusive ? const Color(0xFF4CAF50) : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'VAT Configuration',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isEditCostVATInclusive ? const Color(0xFF2E7D32) : Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            isEditCostVATInclusive ? 'Cost includes VAT' : 'Cost excludes VAT',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isEditCostVATInclusive ? const Color(0xFF4CAF50) : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setEditDialogState(() {
                                          isEditCostVATInclusive = !isEditCostVATInclusive;
                                        });
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: isEditCostVATInclusive ? const Color(0xFF4CAF50) : Colors.grey[400],
                                        ),
                                        child: AnimatedAlign(
                                          duration: const Duration(milliseconds: 200),
                                          alignment: isEditCostVATInclusive 
                                              ? Alignment.centerRight 
                                              : Alignment.centerLeft,
                                          child: Container(
                                            width: 20,
                                            height: 20,
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
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editUnitCostController,
                                      label: isEditCostVATInclusive 
                                          ? 'Unit Cost (VAT Inc) *' 
                                          : 'Unit Cost (VAT Exc) *',
                                      icon: Icons.attach_money,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                          return 'Enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernFormField(
                                      controller: editSellingPriceController,
                                      label: 'Selling Price (BHD)',
                                      icon: Icons.sell,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                          return 'Enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Notes Section
                          _buildModernEditSection(
                            'Additional Notes',
                            Icons.note,
                            [
                              _buildModernFormField(
                                controller: editNotesController,
                                label: 'Notes',
                                icon: Icons.description,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Dispose controllers
                            editNameController.dispose();
                            editCategoryController.dispose();
                            editDescriptionController.dispose();
                            editCurrentStockController.dispose();
                            editMinStockController.dispose();
                            editMaxStockController.dispose();
                            editUnitCostController.dispose();
                            editSellingPriceController.dispose();
                            editSupplierController.dispose();
                            editLocationController.dispose();
                            editNotesController.dispose();
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF757575)),
                            foregroundColor: const Color(0xFF757575),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (editFormKey.currentState!.validate()) {
                              try {
                                // Show loading
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
                                        Text('Updating item...'),
                                      ],
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // Prepare updated item data
                                final updatedItemData = {
                                  'id': item['id'], // Keep the original ID
                                  'name': editNameController.text.trim(),
                                  'category': editCategoryController.text.trim(),
                                  'description': editDescriptionController.text.trim(),
                                  'sku': item['sku'] ?? '', // Keep original SKU
                                  'barcode': item['barcode'] ?? '', // Keep original barcode
                                  'unit': item['unit'] ?? 'pcs', // Keep original unit
                                  'currentStock': double.tryParse(editCurrentStockController.text) ?? 0.0,
                                  'minimumStock': double.tryParse(editMinStockController.text) ?? 0.0,
                                  'maximumStock': double.tryParse(editMaxStockController.text) ?? 0.0,
                                  'unitCost': double.tryParse(editUnitCostController.text) ?? 0.0,
                                  'sellingPrice': double.tryParse(editSellingPriceController.text) ?? 0.0,
                                  'supplier': editSupplierController.text.trim(),
                                  'location': editLocationController.text.trim(),
                                  'status': item['status'] ?? 'Active', // Keep original status
                                  'notes': editNotesController.text.trim(),
                                  'dateAdded': item['dateAdded'], // Keep original date
                                  'lastUpdated': DateTime.now().toIso8601String(), // Add update timestamp
                                };

                                // Update the item
                                final success = await _excelService.updateInventoryItem(updatedItemData);
                                
                                if (success) {
                                  await _loadInventoryData();
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 16),
                                            Text('${editNameController.text} updated successfully!'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error, color: Colors.white),
                                            SizedBox(width: 16),
                                            Text('Failed to update item. Please try again.'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                                
                                // Dispose controllers
                                editNameController.dispose();
                                editCategoryController.dispose();
                                editDescriptionController.dispose();
                                editCurrentStockController.dispose();
                                editMinStockController.dispose();
                                editMaxStockController.dispose();
                                editUnitCostController.dispose();
                                editSellingPriceController.dispose();
                                editSupplierController.dispose();
                                editLocationController.dispose();
                                editNotesController.dispose();
                                
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error, color: Colors.white),
                                          const SizedBox(width: 16),
                                          Expanded(child: Text('Error updating item: ${e.toString()}')),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> item) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${item['name']}"?'),
                const SizedBox(height: 16),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteItem(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    try {
      final bool success = await ExcelService().deleteInventoryItem(item['id'].toString());
      if (success) {
        await _loadInventoryData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods for modern dialog
  Widget _buildModernSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8F5E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? const Color(0xFF616161),
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStockStatusIcon(int currentStock) {
    if (currentStock <= 0) {
      return Icons.error;
    } else if (currentStock <= 5) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  String _getStockStatusText(int currentStock) {
    if (currentStock <= 0) {
      return 'Out of Stock';
    } else if (currentStock <= 5) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  Color _getStockStatusColor(int currentStock) {
    if (currentStock <= 0) {
      return const Color(0xFFE57373);
    } else if (currentStock <= 5) {
      return const Color(0xFFFFB74D);
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  // Helper methods for modern edit dialog
  Widget _buildModernEditSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8F5E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildModernFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE57373)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(
          color: Color(0xFF616161),
          fontSize: 14,
        ),
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF212121),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
