import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class CategoryManagementWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  const CategoryManagementWidget({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  _CategoryManagementWidgetState createState() => _CategoryManagementWidgetState();
}

class _CategoryManagementWidgetState extends State<CategoryManagementWidget> {
  List<String> _availableCategories = [];
  final TextEditingController _newCategoryController = TextEditingController();
  
  // Add a key to force dropdown rebuild
  Key _dropdownKey = UniqueKey();

  // Default categories
  final List<String> _defaultCategories = [
    'Vendor Payments',
    'Salary',
    'Office Supplies',
    'Marketing',
    'Travel',
    'Utilities',
    'Rent',
    'Equipment',
    'Professional Services',
    'Insurance',
    'Taxes',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final categoriesFile = File('${documentsDir.path}/expense_categories.json');
      
      if (await categoriesFile.exists()) {
        final jsonString = await categoriesFile.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          _availableCategories = jsonList.cast<String>();
        });
      } else {
        // Use default categories if file doesn't exist
        setState(() {
          _availableCategories = List.from(_defaultCategories);
        });
        _saveCategories(); // Save defaults to file
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _availableCategories = List.from(_defaultCategories);
      });
    }
  }

  Future<void> _saveCategories() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final categoriesFile = File('${documentsDir.path}/expense_categories.json');
      final jsonString = json.encode(_availableCategories);
      await categoriesFile.writeAsString(jsonString);
      print('Categories saved: $_availableCategories');
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  void _addNewCategory() {
    final categoryName = _newCategoryController.text.trim();
    if (categoryName.isNotEmpty && !_availableCategories.contains(categoryName)) {
      setState(() {
        _availableCategories.add(categoryName);
        _newCategoryController.clear();
        // Force dropdown to rebuild
        _dropdownKey = UniqueKey();
      });
      _saveCategories();
      
      // Auto-select the new category
      widget.onCategoryChanged(categoryName);
      
      Navigator.of(context).pop(); // Close dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$categoryName" added and selected'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_availableCategories.contains(categoryName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteCategory(String category) {
    // Immediate deletion without confirmation dialog
    setState(() {
      _availableCategories.remove(category);
      // If the deleted category was selected, clear selection
      if (widget.selectedCategory == category) {
        widget.onCategoryChanged(null);
      }
      // Force dropdown to rebuild by changing its key
      _dropdownKey = UniqueKey();
    });
    
    // Save to file
    _saveCategories();
    
    // Show brief success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Category "$category" deleted'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Category:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: _dropdownKey, // Add the key here to force rebuild
            value: widget.selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            hint: const Text('Select Category'),
            items: [
              // Add Category option
              const DropdownMenuItem<String>(
                value: '__ADD_NEW__',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add New Category...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              const DropdownMenuItem<String>(
                value: '__DIVIDER__',
                enabled: false,
                child: Divider(height: 1),
              ),
              
              // Clear selection option
              const DropdownMenuItem<String>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('All Categories'),
                  ],
                ),
              ),
              
              // Regular categories with delete option
              ..._availableCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          // Prevent dropdown selection when tapping delete
                          _deleteCategory(category);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            onChanged: (value) {
              if (value == '__ADD_NEW__') {
                _showAddCategoryDialog();
              } else if (value != '__DIVIDER__') {
                widget.onCategoryChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vendor payments':
        return Icons.business;
      case 'salary':
        return Icons.person;
      case 'office supplies':
        return Icons.inventory;
      case 'marketing':
        return Icons.campaign;
      case 'travel':
        return Icons.flight;
      case 'utilities':
        return Icons.electrical_services;
      case 'rent':
        return Icons.home;
      case 'equipment':
        return Icons.computer;
      case 'professional services':
        return Icons.work;
      case 'insurance':
        return Icons.security;
      case 'taxes':
        return Icons.account_balance;
      default:
        return Icons.receipt_long;
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.orange),
            SizedBox(width: 8),
            Text('Add New Category'),
          ],
        ),
        content: TextField(
          controller: _newCategoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter category name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _addNewCategory(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newCategoryController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addNewCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }
}
