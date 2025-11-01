import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/excel_service.dart';
import '../../services/simple_navigation.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final ExcelService _excelService = ExcelService();
  late FocusNode _focusNode;
  
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadInventoryData();
    print('📦 InventoryManagementScreen initialized with ESC key support');
    
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      print('🎯 Focus requested for InventoryManagementScreen');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load inventory items from inventory_items.xlsx
      final materials = await _excelService.loadInventoryItemsFromExcel();
      
      // Load vendors from Excel
      final vendors = await _excelService.loadVendorsFromExcel();
      
      setState(() {
        _materials = materials;
        _vendors = vendors;
        _isLoading = false;
        
        // Debug output
        print('🔍 DEBUG: Loaded ${materials.length} materials');
        if (materials.isNotEmpty) {
          print('🔍 DEBUG: First material: ${materials.first}');
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    var filtered = _materials.where((material) {
      final name = material['name']?.toString().toLowerCase() ?? '';
      final category = material['category']?.toString().toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();
      
      final matchesSearch = name.contains(searchLower) || category.contains(searchLower);
      final matchesCategory = _selectedCategory == null || category == _selectedCategory?.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    return filtered;
  }

  List<String> get _categories {
    final categories = _materials
        .map((m) => m['category']?.toString())
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          print('🔑 ESC pressed in Inventory Management');
          NavigationService.handleEscapeKey(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Management'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddNewMaterialDialog,
              tooltip: 'Add New Material',
            ),
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: _showVendorsDialog,
              tooltip: 'Manage Vendors',
            ),
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text('Error: $_error'))
            : Column(
                children: [
                  // Header with search and filters
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search materials...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Category filter
                        Row(
                          children: [
                            const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                hint: const Text('All Categories'),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Categories'),
                                  ),
                                  ..._categories.map((category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Materials inventory list
                  Expanded(
                    child: _filteredMaterials.isEmpty
                      ? const Center(child: Text('No materials found'))
                      : ListView.builder(
                          itemCount: _filteredMaterials.length,
                          itemBuilder: (context, index) {
                            final material = _filteredMaterials[index];
                            return _buildMaterialCard(material);
                          },
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final stockQuantity = material['currentStock'] as double? ?? 0.0;
    final minStockLevel = material['minimumStock'] as double? ?? 10.0;
    final price = material['sellingPrice'] as double? ?? 0.0;
    final unit = material['unit'] as String? ?? 'units';
    final supplier = material['supplier'] as String? ?? 'Unknown Supplier';
    final isLowStock = stockQuantity <= minStockLevel;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showMaterialDetailsDialog(material),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material['name'] ?? 'Unknown Material',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        material['category'] ?? 'Uncategorized',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (supplier.isNotEmpty && supplier != 'Unknown Supplier')
                        Text(
                          'Supplier: $supplier',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red : stockQuantity > 0 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLowStock ? 'Low Stock' : stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Stock and price info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock: ${stockQuantity.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isLowStock ? Colors.red : Colors.black,
                        ),
                      ),
                      Text(
                        'Min Level: ${minStockLevel.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Price: BHD ${price.toStringAsFixed(2)} per $unit',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showEditMaterialDialog(material),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showPurchaseDialog(material: material),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Purchase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteMaterial(material),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Delete Material',
                    ),
                  ],
                ),
              ],
            ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tap for details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaterialDetailsDialog(Map<String, dynamic> material) {
    final stockQuantity = material['currentStock'] as double? ?? 0.0;
    final minStockLevel = material['minimumStock'] as double? ?? 10.0;
    final unit = material['unit'] as String? ?? 'units';
    final supplier = material['supplier'] as String? ?? 'Unknown Supplier';
    final costPrice = material['unitCost'] as double? ?? 0.0;
    final sellingPrice = material['sellingPrice'] as double? ?? 0.0;
    final isLowStock = stockQuantity <= minStockLevel;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.white,
                  Colors.green.shade50,
                ],
              ),
            ),
            child: Column(
              children: [
                // 🎨 MODERN HEADER WITH GRADIENT
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade700,
                        Colors.green.shade800,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade300.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  material['name'] ?? 'Unknown Material',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Item ID: ${material['id'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isLowStock ? Colors.red.shade400 : stockQuantity > 0 ? Colors.green.shade400 : Colors.orange.shade400,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              isLowStock ? 'Low Stock' : stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '📂 ${material['category'] ?? 'Uncategorized'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '📦 ${stockQuantity.toStringAsFixed(1)} $unit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // � CONTENT SECTIONS
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 💰 PRICING SECTION
                        _buildModernInfoCard(
                          title: '💰 Pricing Information',
                          icon: Icons.attach_money,
                          children: [
                            _buildModernDetailRow('Cost Price', 'BHD ${costPrice.toStringAsFixed(2)} per $unit', Icons.shopping_cart),
                            _buildModernDetailRow('Selling Price', 'BHD ${sellingPrice.toStringAsFixed(2)} per $unit', Icons.sell),
                            _buildModernDetailRow('Profit Margin', 'BHD ${(sellingPrice - costPrice).toStringAsFixed(2)} per $unit', Icons.trending_up),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 📦 INVENTORY SECTION
                        _buildModernInfoCard(
                          title: '📦 Inventory Status',
                          icon: Icons.inventory_2,
                          children: [
                            _buildModernDetailRow('Current Stock', '${stockQuantity.toStringAsFixed(1)} $unit', Icons.storage),
                            _buildModernDetailRow('Minimum Level', '${minStockLevel.toStringAsFixed(1)} $unit', Icons.warning_amber),
                            _buildModernDetailRow('Unit Type', unit, Icons.straighten),
                            if (supplier.isNotEmpty && supplier != 'Unknown Supplier')
                              _buildModernDetailRow('Supplier', supplier, Icons.business),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 📋 ADDITIONAL INFO SECTION
                        if (material['notes']?.toString().isNotEmpty == true)
                          _buildModernInfoCard(
                            title: '📋 Additional Information',
                            icon: Icons.info_outline,
                            children: [
                              _buildModernDetailRow('Notes', material['notes'].toString(), Icons.note_alt),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                
                // 🚀 MODERN ACTION FOOTER
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    children: [
                      // Stock Status Indicator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLowStock 
                              ? [Colors.red.shade100, Colors.red.shade50]
                              : stockQuantity > 0 
                                ? [Colors.green.shade100, Colors.green.shade50]
                                : [Colors.orange.shade100, Colors.orange.shade50],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLowStock 
                              ? Colors.red.shade300
                              : stockQuantity > 0 
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLowStock 
                                ? Icons.warning_amber
                                : stockQuantity > 0 
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: isLowStock 
                                ? Colors.red.shade600
                                : stockQuantity > 0 
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isLowStock 
                                  ? 'Stock is running low! Consider restocking soon.'
                                  : stockQuantity > 0 
                                    ? 'Stock levels are healthy.'
                                    : 'Item is out of stock! Immediate restocking required.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isLowStock 
                                    ? Colors.red.shade700
                                    : stockQuantity > 0 
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                foregroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Navigate to purchase entry screen with pre-filled item name
                                context.go('/purchase-entries/new?itemName=${Uri.encodeComponent(material['name'] ?? '')}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text(
                                'Purchase More',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _showPurchaseDialog({Map<String, dynamic>? material}) {
    showDialog(
      context: context,
      builder: (context) => PurchaseDialog(
        material: material,
        vendors: _vendors,
        excelService: _excelService,
        onPurchaseComplete: _loadInventoryData,
      ),
    );
  }

  void _showVendorsDialog() {
    context.go('/vendors');
  }

  void _showEditMaterialDialog(Map<String, dynamic> material) {
    showDialog(
      context: context,
      builder: (context) => EditMaterialDialog(
        material: material,
        excelService: _excelService,
        onMaterialUpdated: _loadInventoryData,
        existingCategories: _categories,
      ),
    );
  }

  void _showAddNewMaterialDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNewMaterialDialog(
        excelService: _excelService,
        onMaterialAdded: _loadInventoryData,
        existingCategories: _categories,
      ),
    );
  }

  // Delete material with confirmation dialog
  void _deleteMaterial(Map<String, dynamic> material) {
    final materialName = material['name'] ?? 'Unknown Material';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to remove $materialName from the inventory?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDelete(material);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Perform the actual deletion
  Future<void> _performDelete(Map<String, dynamic> material) async {
    try {
      final materialId = material['id']?.toString();
      
      if (materialId == null || materialId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Material ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call the ExcelService delete method
      final success = await _excelService.deleteMaterial(materialId);
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${material['name']} has been deleted from inventory'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the inventory data to reflect the changes
        await _loadInventoryData();
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ${material['name']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting material: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class PurchaseDialog extends StatefulWidget {
  final Map<String, dynamic>? material;
  final List<Map<String, dynamic>> vendors;
  final ExcelService excelService;
  final VoidCallback onPurchaseComplete;

  const PurchaseDialog({
    super.key,
    this.material,
    required this.vendors,
    required this.excelService,
    required this.onPurchaseComplete,
  });

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purchaseCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  
  String? _selectedVendorId;
  String _paymentType = 'credit'; // 'credit' or 'cash'

  @override
  void dispose() {
    _quantityController.dispose();
    _purchaseCostController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🟢 GREEN HEADER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.material != null 
                            ? 'Purchase ${widget.material!['name']}'
                            : 'Purchase Materials',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _paymentType == 'credit' ? 'On Credit' : 'Pay Now',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.material != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category: ${widget.material!['category'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Current Stock: ${(widget.material!['currentStock'] ?? 0.0).toStringAsFixed(1)} ${widget.material!['unit'] ?? 'units'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // 📦 MAIN CONTENT SECTION
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
              // Vendor selection
              DropdownButtonFormField<String>(
                value: _selectedVendorId,
                decoration: const InputDecoration(
                  labelText: 'Select Vendor',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...widget.vendors.map((vendor) => DropdownMenuItem<String>(
                    value: vendor['id'],
                    child: Text(vendor['name']),
                  )),
                  const DropdownMenuItem<String>(
                    value: 'new',
                    child: Text('+ Add New Vendor'),
                  ),
                ],
                onChanged: (value) {
                  if (value == 'new') {
                    _showAddVendorDialog();
                  } else {
                    setState(() {
                      _selectedVendorId = value;
                    });
                  }
                },
                validator: (value) => value == null ? 'Please select a vendor' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Purchase Cost per unit
              TextFormField(
                controller: _purchaseCostController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Cost per unit (BHD)',
                  border: OutlineInputBorder(),
                  helperText: 'The cost you pay to buy this material',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purchase cost';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid purchase cost';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Selling Price per unit
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price per unit (BHD)',
                  border: OutlineInputBorder(),
                  helperText: 'The price you will charge customers for this material',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter selling price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid selling price';
                  }
                  // Validate that selling price is not less than purchase cost
                  final purchaseCost = double.tryParse(_purchaseCostController.text) ?? 0;
                  final sellingPrice = double.tryParse(value) ?? 0;
                  if (sellingPrice < purchaseCost) {
                    return 'Selling price should not be less than purchase cost';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Payment type
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('On Credit'),
                    value: 'credit',
                    groupValue: _paymentType,
                    onChanged: (value) {
                      setState(() {
                        _paymentType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Pay Now'),
                    value: 'cash',
                    groupValue: _paymentType,
                    onChanged: (value) {
                      setState(() {
                        _paymentType = value!;
                      });
                    },
                  ),
                ],
              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
            // 💰 FOOTER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _processPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(_paymentType == 'cash' ? 'Pay Now' : 'Add to Credit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPurchase() {
    if (_formKey.currentState!.validate()) {
      final quantity = double.parse(_quantityController.text);
      final purchaseCost = double.parse(_purchaseCostController.text);
      final sellingPrice = double.parse(_sellingPriceController.text);
      final totalAmount = quantity * purchaseCost;
      
      if (_paymentType == 'cash') {
        // Navigate to payment screen
        Navigator.of(context).pop();
        _showPaymentScreen(totalAmount);
      } else {
        // Process credit purchase
        _processCreditPurchase(quantity, purchaseCost, sellingPrice);
      }
    }
  }

  void _processCreditPurchase(double quantity, double purchaseCost, double sellingPrice) async {
    final material = widget.material;
    if (material != null) {
      final materialId = material['id'] as String;
      
      // Update material stock in Excel
      final success = await widget.excelService.addMaterialStock(materialId, quantity, purchaseCost, sellingPrice);
      
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase added to credit. ${quantity.toStringAsFixed(1)} units added to stock. Total: BHD ${(quantity * purchaseCost).toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update stock. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      widget.onPurchaseComplete();
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase added to credit. Total: BHD ${(quantity * purchaseCost).toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onPurchaseComplete();
    }
  }

  void _showPaymentScreen(double totalAmount) {
    final quantity = double.parse(_quantityController.text);
    final purchaseCost = double.parse(_purchaseCostController.text);
    final sellingPrice = double.parse(_sellingPriceController.text);
    
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        amount: totalAmount,
        material: widget.material,
        quantity: quantity,
        purchaseCost: purchaseCost,
        sellingPrice: sellingPrice,
        excelService: widget.excelService,
        onPaymentComplete: () {
          widget.onPurchaseComplete();
        },
      ),
    );
  }

  void _showAddVendorDialog() {
    // Navigate to vendor management screen
    context.go('/vendors');
  }
}

class PaymentDialog extends StatefulWidget {
  final double amount;
  final Map<String, dynamic>? material;
  final double? quantity;
  final double? purchaseCost;
  final double? sellingPrice;
  final ExcelService excelService;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.amount,
    this.material,
    this.quantity,
    this.purchaseCost,
    this.sellingPrice,
    required this.excelService,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🟢 GREEN HEADER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'BHD ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 📦 MAIN CONTENT SECTION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Amount: BHD ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Payment Method:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
          RadioListTile<String>(
            title: const Text('Cash'),
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Bank Transfer'),
            value: 'bank',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Credit Card'),
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
                  ],
                ),
              ),
            ),
            
            // 💰 FOOTER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      // Update stock if material, quantity, purchaseCost and sellingPrice are provided
                      if (widget.material != null && widget.quantity != null && widget.purchaseCost != null && widget.sellingPrice != null) {
                        final materialId = widget.material!['id'] as String;
                        final success = await widget.excelService.addMaterialStock(
                          materialId, 
                          widget.quantity!, 
                          widget.purchaseCost!,
                          widget.sellingPrice!
                        );
                        
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Close purchase dialog too
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment of BHD ${widget.amount.toStringAsFixed(2)} processed successfully! ${widget.quantity!.toStringAsFixed(1)} units added to stock.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment processed but failed to update stock. Please check inventory manually.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } else {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Close purchase dialog too
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment of BHD ${widget.amount.toStringAsFixed(2)} processed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      
                      widget.onPaymentComplete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Process Payment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> vendors;
  final Function(List<Map<String, dynamic>>) onVendorsUpdated;

  const VendorsDialog({
    super.key,
    required this.vendors,
    required this.onVendorsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vendor Management'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return Card(
              child: ListTile(
                title: Text(vendor['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact: ${vendor['contact']}'),
                    Text('Credit: BHD ${vendor['currentCredit']} / ${vendor['creditLimit']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit vendor functionality
                  },
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Add new vendor functionality
          },
          child: const Text('Add Vendor'),
        ),
      ],
    );
  }
}

class AddNewMaterialDialog extends StatefulWidget {
  final ExcelService excelService;
  final VoidCallback onMaterialAdded;
  final List<String> existingCategories;

  const AddNewMaterialDialog({
    super.key,
    required this.excelService,
    required this.onMaterialAdded,
    required this.existingCategories,
  });

  @override
  State<AddNewMaterialDialog> createState() => _AddNewMaterialDialogState();
}

class _AddNewMaterialDialogState extends State<AddNewMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitCostController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🟢 GREEN HEADER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Form',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 📦 MAIN CONTENT SECTION
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Unit Cost
              TextFormField(
                controller: _unitCostController,
                decoration: InputDecoration(
                  labelText: 'Unit Cost (BHD) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit cost';
                  }
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) {
                    return 'Please enter valid unit cost';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selling Price
              TextFormField(
                controller: _sellingPriceController,
                decoration: InputDecoration(
                  labelText: 'Selling Price (BHD) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.sell),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter selling price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Please enter valid selling price';
                  }
                  return null;
                },
              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // 💰 FOOTER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _addInventoryItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add Item'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addInventoryItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        // Generate unique Item ID
        final itemId = 'ITM${DateTime.now().millisecondsSinceEpoch}';
        
        // Create comprehensive inventory item data matching Excel structure
        final newItem = {
          'id': itemId,                                                              // Column A: Item ID
          'name': _nameController.text.trim(),                                       // Column B: Name
          'category': _categoryController.text.trim(),                               // Column C: Category
          'description': '',                                                         // Column D: Description
          'sku': '',                                                                 // Column E: SKU
          'barcode': '',                                                             // Column F: Barcode
          'unit': 'pcs',                                                             // Column G: Unit
          'quantity': 0.0,                                                           // Column H: Current Stock (quantity for Excel)
          'minimumStock': 0.0,                                                       // Column I: Minimum Stock
          'maximumStock': 0.0,                                                       // Column J: Maximum Stock
          'costPrice': double.parse(_unitCostController.text),                       // Column K: Cost Price (costPrice for Excel)
          'sellingPrice': double.parse(_sellingPriceController.text),                // Column L: Selling Price
          'supplier': '',                                                            // Column M: Supplier
          'location': '',                                                            // Column N: Location
          'status': 'Active',                                                        // Column O: Status
          'purchaseDate': DateTime.now().toIso8601String().split('T')[0],           // Column P: Purchase Date (today)
          'lastUpdated': DateTime.now().toIso8601String(),                          // Column Q: Last Updated
          'notes': '',                                                               // Column R: Notes
        };

        final success = await widget.excelService.saveInventoryItemToExcel(newItem);
        
        if (success) {
          // Return the newly created item to the caller so other screens (like Purchase) can use it
          Navigator.of(context).pop(newItem);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inventory item "${_nameController.text.trim()}" added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onMaterialAdded();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add inventory item. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding inventory item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }
}

class EditMaterialDialog extends StatefulWidget {
  final Map<String, dynamic> material;
  final ExcelService excelService;
  final VoidCallback onMaterialUpdated;
  final List<String> existingCategories;

  const EditMaterialDialog({
    super.key,
    required this.material,
    required this.excelService,
    required this.onMaterialUpdated,
    required this.existingCategories,
  });

  @override
  State<EditMaterialDialog> createState() => _EditMaterialDialogState();
}

class _EditMaterialDialogState extends State<EditMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _purchaseCostController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _unitController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _supplierController;
  late final TextEditingController _notesController;

  String? _selectedCategory;
  bool _useExistingCategory = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current material data
    _nameController = TextEditingController(text: widget.material['name']?.toString() ?? '');
    _purchaseCostController = TextEditingController(text: widget.material['purchaseCost']?.toString() ?? '0');
    _sellingPriceController = TextEditingController(text: widget.material['sellingPrice']?.toString() ?? '0');
    _unitController = TextEditingController(text: widget.material['unit']?.toString() ?? 'units');
    _stockController = TextEditingController(text: widget.material['currentStock']?.toString() ?? '0');
    _minStockController = TextEditingController(text: widget.material['minimumStock']?.toString() ?? '10');
    _supplierController = TextEditingController(text: widget.material['supplier']?.toString() ?? '');
    _notesController = TextEditingController(text: widget.material['notes']?.toString() ?? '');
    
    // Set up category
    final currentCategory = widget.material['category']?.toString() ?? '';
    if (widget.existingCategories.contains(currentCategory)) {
      _useExistingCategory = true;
      _selectedCategory = currentCategory;
      _categoryController = TextEditingController();
    } else {
      _useExistingCategory = false;
      _selectedCategory = null;
      _categoryController = TextEditingController(text: currentCategory);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _purchaseCostController.dispose();
    _sellingPriceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🟢 GREEN HEADER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Material',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.material['name']?.toString().split(' ').first ?? 'Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 📦 MAIN CONTENT SECTION
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
              // Material Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter material name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<bool>(
                    title: const Text('Use existing category'),
                    value: true,
                    groupValue: _useExistingCategory,
                    onChanged: (value) {
                      setState(() {
                        _useExistingCategory = value!;
                        if (_useExistingCategory) {
                          _categoryController.clear();
                        } else {
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),
                  if (_useExistingCategory && widget.existingCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select Category'),
                        items: widget.existingCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (_useExistingCategory && (value == null || value.isEmpty)) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ),
                  RadioListTile<bool>(
                    title: const Text('Create new category'),
                    value: false,
                    groupValue: _useExistingCategory,
                    onChanged: (value) {
                      setState(() {
                        _useExistingCategory = value!;
                        if (_useExistingCategory) {
                          _categoryController.clear();
                        } else {
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),
                  if (!_useExistingCategory)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Category Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_useExistingCategory && (value == null || value.trim().isEmpty)) {
                            return 'Please enter category name';
                          }
                          return null;
                        },
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Purchase Cost - Cost when buying the material
              TextFormField(
                controller: _purchaseCostController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Cost per unit (BHD) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_cart),
                  helperText: 'Cost when purchasing from supplier',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter purchase cost';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid cost';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Selling Price - Price when selling to customers
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Selling Price per unit (BHD) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Price when selling to customers',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter selling price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid price';
                  }
                  final purchaseCost = double.tryParse(_purchaseCostController.text) ?? 0;
                  final sellingPrice = double.tryParse(value) ?? 0;
                  if (sellingPrice < purchaseCost) {
                    return 'Selling price should be higher than purchase cost for profit';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Unit
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g., meters, yards, pieces)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Stock Quantity
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Minimum Stock Level
              TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Stock Level',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter minimum stock level';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Supplier
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // 💰 FOOTER SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _updateMaterial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Update Material'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMaterial() async {
    if (_formKey.currentState!.validate()) {
      final category = _useExistingCategory 
          ? _selectedCategory ?? ''
          : _categoryController.text.trim();
      
      if (category.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or enter a category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create updated material data
      final updatedMaterial = {
        'id': widget.material['id'], // Keep the original ID
        'name': _nameController.text.trim(),
        'category': category,
        'purchaseCost': double.parse(_purchaseCostController.text),
        'sellingPrice': double.parse(_sellingPriceController.text),
        'unit': _unitController.text.trim(),
        'currentStock': double.parse(_stockController.text),
        'minimumStock': double.parse(_minStockController.text),
        'supplier': _supplierController.text.trim(),
        'lastUpdated': DateTime.now(),
        'notes': _notesController.text.trim(),
      };

      try {
        final success = await widget.excelService.updateMaterial(updatedMaterial);
        
        Navigator.of(context).pop();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Material "${updatedMaterial['name']}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onMaterialUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update material. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
