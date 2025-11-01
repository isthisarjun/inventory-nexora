import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/services/excel_service.dart';
import 'package:tailor_v3/theme/colors.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExcelService _excelService = ExcelService();
  
  // Controllers
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();
  
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
  
  // Calculated values
  double _itemTotal = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
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
      });
    } catch (e) {
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateItemTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final unitCost = double.tryParse(_unitCostController.text) ?? 0.0;
    setState(() {
      _itemTotal = quantity * unitCost;
    });
  }

  void _addItemToPurchase() {
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
    };
    
    setState(() {
      _purchaseItems.add(purchaseItem);
      _selectedItemId = null;
      _quantityController.clear();
      _unitCostController.clear();
      _itemTotal = 0.0;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVendorId == null) {
      _showErrorSnackBar('Please select a vendor');
      return;
    }
    
    if (_purchaseItems.isEmpty) {
      _showErrorSnackBar('Please add at least one item');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final selectedVendor = _vendors.firstWhere(
        (vendor) => vendor['vendorId'] == _selectedVendorId,
      );
      
      final purchaseId = 'PUR${DateTime.now().millisecondsSinceEpoch}';
      
      final purchaseData = {
        'id': purchaseId,
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
        for (final item in _purchaseItems) {
          await _excelService.updateInventoryQuantity(
            item['itemId'],
            item['quantity'],
          );
        }
        
        _showSuccessSnackBar('Purchase saved successfully!');
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
      _itemTotal = 0.0;
    });
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
        title: const Text('New Purchase Entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
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
                          Row(
                            children: [
                              Expanded(child: _buildDatePicker()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPurchaseIdDisplay()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildItemDropdown(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildQuantityField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildUnitCostField()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withOpacity(0.1),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Amount:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'BHD ${_itemTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _addItemToPurchase,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.primary, thickness: 1),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildVendorDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVendorId,
      decoration: InputDecoration(
        labelText: 'Vendor ID *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.business, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _vendors.map((vendor) {
        return DropdownMenuItem<String>(
          value: vendor['vendorId'],
          child: Text('${vendor['vendorId']} - ${vendor['vendorName']}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedVendorId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a vendor';
        }
        return null;
      },
      isExpanded: true,
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
            'Vendor Name: ${vendor['vendorName']}',
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Purchase Date *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildPurchaseIdDisplay() {
    final purchaseId = 'PUR${DateTime.now().millisecondsSinceEpoch}';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Purchase ID (Auto-generated)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.receipt_long, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
      ),
      child: Text(
        purchaseId,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildItemDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedItemId,
      decoration: InputDecoration(
        labelText: 'Item ID *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.inventory, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _inventoryItems.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'],
          child: Text('${item['id']} - ${item['name']}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedItemId = value;
        });
      },
      isExpanded: true,
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Quantity *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (_) => _calculateItemTotal(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter quantity';
        }
        final qty = double.tryParse(value);
        if (qty == null || qty <= 0) {
          return 'Please enter valid quantity';
        }
        return null;
      },
    );
  }

  Widget _buildUnitCostField() {
    return TextFormField(
      controller: _unitCostController,
      decoration: InputDecoration(
        labelText: 'Cost Price per Unit (BHD) *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (_) => _calculateItemTotal(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter unit cost';
        }
        final cost = double.tryParse(value);
        if (cost == null || cost <= 0) {
          return 'Please enter valid unit cost';
        }
        return null;
      },
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
              subtitle: Text(
                'Qty: ${item['quantity']} ${item['unit']} × BHD ${item['unitCost'].toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textSecondary),
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