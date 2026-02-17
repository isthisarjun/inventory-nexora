import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/excel_service.dart';
import '../../services/simple_navigation.dart';

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen> {
  final ExcelService _excelService = ExcelService();
  late FocusNode _focusNode;
  
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadVendors();
    print('👥 VendorManagementScreen initialized with ESC key support');
    
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      print('🎯 Focus requested for VendorManagementScreen');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _loadVendors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vendors = await _excelService.loadVendorsFromExcel();
      setState(() {
        _vendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredVendors {
    if (_searchQuery.isEmpty) {
      return _vendors;
    }
    return _vendors.where((vendor) {
      final name = vendor['vendorName']?.toString().toLowerCase() ?? '';
      final email = vendor['email']?.toString().toLowerCase() ?? '';
      final phone = vendor['phone']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || 
             email.contains(query) || 
             phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          print('🔑 ESC pressed in Vendor Management');
          NavigationService.handleEscapeKey(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        title: const Text('Vendors'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddVendorDialog,
            tooltip: 'Add New Vendor',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVendors,
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
                    onPressed: _loadVendors,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green[50], // Changed to green accent
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Total Vendors Card
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      '${_vendors.where((v) => v['status'] == 'Active').length}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green, // Changed to green accent
                                      ),
                                    ),
                                    const Text('Total Vendors'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Active Credit Card
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    FutureBuilder<double>(
                                      future: _calculateTotalActiveCredit(),
                                      builder: (context, snapshot) {
                                        return Text(
                                          'BHD ${(snapshot.data ?? 0.0).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red, // Changed to red
                                          ),
                                        );
                                      },
                                    ),
                                    const Text('Total Credit'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Search Bar
                      Card(
                        elevation: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search vendors by name, email, or phone...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vendors list - Simple Names Only
                Expanded(
                  child: _vendors.isEmpty
                      ? const Center(
                          child: Text('No vendors found. Add some vendors to get started!'),
                        )
                      : _filteredVendors.isEmpty
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
                                    'No vendors found for "$_searchQuery"',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredVendors.length,
                              itemBuilder: (context, index) {
                                final vendor = _filteredVendors[index];
                                return _buildSimpleVendorCard(vendor);
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVendorDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ),
    );
  }

  Future<double> _calculateTotalActiveCredit() async {
    return _vendors.where((vendor) => vendor['status'] == 'Active').fold<double>(
      0.0,
      (total, vendor) => total + (vendor['currentCredit'] as double? ?? 0.0),
    );
  }

  Widget _buildSimpleVendorCard(Map<String, dynamic> vendor) {
    final creditAmount = vendor['currentCredit'] as double? ?? 0.0;
    final hasActiveCredit = creditAmount > 0;
    final vendorName = vendor['vendorName']?.toString() ?? 'Unknown Vendor';

    if (vendorName.isEmpty) {
      print('Error: Vendor name is missing for vendor: $vendor');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasActiveCredit 
              ? BorderSide(color: Colors.green[200]!, width: 1) // Changed to green accent
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: vendorName.isNotEmpty
              ? () => _navigateToVendorDashboard(vendorName)
              : null, // Disable tap if vendorName is invalid
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100], // Changed to green accent
                  child: Text(
                    vendorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // Changed to green accent
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vendorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (hasActiveCredit)
                        Text(
                          'BHD ${creditAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green, // Changed to green accent
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToVendorDashboard(String? vendorName) {
    if (vendorName == null || vendorName.isEmpty) {
      print('Error: Vendor name is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to navigate: Vendor name is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final encodedVendorName = Uri.encodeComponent(vendorName);
      print('Navigating to Vendor Dashboard with vendorName: $vendorName');
      print('Encoded vendorName: $encodedVendorName');
      context.push('/vendor-dashboard/$encodedVendorName');
      print('Navigation to /vendor-dashboard/$encodedVendorName successful');
    } catch (e, stackTrace) {
      print('Error navigating to vendor dashboard: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to navigate to vendor dashboard'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddVendorDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVendorDialog(
        onVendorAdded: (vendor) async {
          // Save to Excel
          final success = await _excelService.addVendorToExcel(vendor);
          if (success) {
            // Reload vendors from Excel
            _loadVendors();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vendor "${vendor['vendorName']}" added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add vendor. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

class AddVendorDialog extends StatefulWidget {
  final Map<String, dynamic>? vendor;
  final Function(Map<String, dynamic>) onVendorAdded;

  const AddVendorDialog({
    super.key,
    this.vendor,
    required this.onVendorAdded,
  });

  @override
  State<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _maximumCreditController = TextEditingController(text: '0');
  final _creditLimitController = TextEditingController(text: '0');
  final _specialtiesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _nameController.text = widget.vendor!['vendorName'] ?? '';
      _contactController.text = widget.vendor!['phone'] ?? '';
      _emailController.text = widget.vendor!['email'] ?? '';
      _addressController.text = widget.vendor!['address'] ?? '';
      _cityController.text = widget.vendor!['city'] ?? '';
      _countryController.text = widget.vendor!['country'] ?? '';
      _vatNumberController.text = widget.vendor!['vatNumber'] ?? '';
      _maximumCreditController.text = widget.vendor!['maximumCredit']?.toString() ?? '0';
      _creditLimitController.text = widget.vendor!['currentCredit']?.toString() ?? '0';
      _specialtiesController.text = ''; // Not used in Excel schema
      _notesController.text = widget.vendor!['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _vatNumberController.dispose();
    _maximumCreditController.dispose();
    _creditLimitController.dispose();
    _specialtiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vendor != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[300]!, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Icon(
                    isEditing ? Icons.edit : Icons.person_add,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Vendor' : 'Add New Vendor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Row 1: Vendor Name, Contact Number, Email
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: const InputDecoration(
                                    labelText: 'Vendor Name *',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter vendor name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _contactController,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Number *',
                                    border: OutlineInputBorder(),
                                    hintText: '+973 1234 5678',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter contact number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address *',
                                    border: OutlineInputBorder(),
                                    hintText: 'vendor@example.com',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter email address';
                                    }
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Row 2: Address (full width)
                        SizedBox(
                          height: 60,
                          child: TextFormField(
                            controller: _addressController,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Address (optional)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Row 3: City, Country, VAT Number
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _cityController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., Manama',
                                    prefixIcon: Icon(Icons.location_city, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _countryController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: const InputDecoration(
                                    labelText: 'Country',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., Bahrain',
                                    prefixIcon: Icon(Icons.flag, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _vatNumberController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: const InputDecoration(
                                    labelText: 'VAT Number',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., VAT123456789',
                                    prefixIcon: Icon(Icons.numbers, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Row 4: Maximum Credit, Current Credit, empty slot
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _maximumCreditController,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Maximum Credit (BHD)',
                                    border: OutlineInputBorder(),
                                    hintText: '0.000',
                                    prefixIcon: Icon(Icons.credit_card, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                                        return 'Please enter a valid maximum credit amount';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _creditLimitController,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Current Credit (BHD)',
                                    border: OutlineInputBorder(),
                                    hintText: '0.000',
                                    prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                                        return 'Please enter a valid current credit amount';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()), // Empty space for 3-column layout
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Row 5: Specialties (full width)
                        SizedBox(
                          height: 60,
                          child: TextFormField(
                            controller: _specialtiesController,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Specialties (comma separated)',
                              border: OutlineInputBorder(),
                              hintText: 'Cotton, Silk, Linen',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Row 6: Notes (full width)
                        SizedBox(
                          height: 60,
                          child: TextFormField(
                            controller: _notesController,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Additional information about this vendor',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveVendor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditing ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEditing ? 'Update Vendor' : 'Add Vendor'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVendor() async {
    if (_isSaving) return;
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        final vendor = {
          'vendorId': widget.vendor?['vendorId'] ?? _generateVendorId(_nameController.text.trim()),
          'vendorName': _nameController.text.trim(),
          'phone': _contactController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'vatNumber': _vatNumberController.text.trim(),
          'maximumCredit': double.tryParse(_maximumCreditController.text) ?? 0.0,
          'currentCredit': double.tryParse(_creditLimitController.text) ?? 0.0,
          'notes': _notesController.text.trim(),
          'status': 'Active',
          'dateAdded': widget.vendor?['dateAdded']?.toString() ?? DateTime.now().toIso8601String(),
          'totalPurchases': 0.0,
          'lastPurchaseDate': '',
        };

        Navigator.of(context).pop();
        widget.onVendorAdded(vendor);
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  String _generateVendorId(String name) {
    final cleanName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'vendor_${cleanName}_$timestamp';
  }
}

// Real-time vendor edit dialog with auto-save functionality
class RealTimeVendorEditDialog extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final ExcelService excelService;
  final VoidCallback onVendorUpdated;

  const RealTimeVendorEditDialog({
    super.key,
    required this.vendor,
    required this.excelService,
    required this.onVendorUpdated,
  });

  @override
  State<RealTimeVendorEditDialog> createState() => _RealTimeVendorEditDialogState();
}

class _RealTimeVendorEditDialogState extends State<RealTimeVendorEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _vatNumberController;
  late final TextEditingController _maximumCreditController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _notesController;

  Timer? _debounceTimer;
  bool _isSaving = false;
  String _lastSavedState = '';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with vendor data
    _nameController = TextEditingController(text: widget.vendor['vendorName'] ?? '');
    _contactController = TextEditingController(text: widget.vendor['phone'] ?? '');
    _emailController = TextEditingController(text: widget.vendor['email'] ?? '');
    _addressController = TextEditingController(text: widget.vendor['address'] ?? '');
    _cityController = TextEditingController(text: widget.vendor['city'] ?? '');
    _countryController = TextEditingController(text: widget.vendor['country'] ?? '');
    _vatNumberController = TextEditingController(text: widget.vendor['vatNumber'] ?? '');
    _maximumCreditController = TextEditingController(text: widget.vendor['maximumCredit']?.toString() ?? '0');
    _creditLimitController = TextEditingController(text: widget.vendor['currentCredit']?.toString() ?? '0');
    _notesController = TextEditingController(text: widget.vendor['notes'] ?? '');
    
    // Store initial state
    _lastSavedState = _getCurrentState();
    
    // Add listeners for real-time updates
    _nameController.addListener(_onFieldChanged);
    _contactController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _vatNumberController.addListener(_onFieldChanged);
    _maximumCreditController.addListener(_onFieldChanged);
    _creditLimitController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _vatNumberController.dispose();
    _maximumCreditController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getCurrentState() {
    return '${_nameController.text}|${_contactController.text}|${_emailController.text}|'
           '${_addressController.text}|${_cityController.text}|${_countryController.text}|'
           '${_vatNumberController.text}|${_maximumCreditController.text}|'
           '${_creditLimitController.text}|${_notesController.text}';
  }

  void _onFieldChanged() {
    final currentState = _getCurrentState();
    if (currentState != _lastSavedState) {
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      // Start new timer (debounce for 1 second)
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        _autoSave();
      });
    }
  }

  Future<void> _autoSave() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedVendor = _createVendorObject();
      final success = await widget.excelService.updateVendorInExcel(updatedVendor);
      
      if (success) {
        _lastSavedState = _getCurrentState();
        widget.onVendorUpdated();
        
        // Show brief success indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Auto-saved'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 500, left: 20, right: 20),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Auto-save failed'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 500, left: 20, right: 20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, dynamic> _createVendorObject() {
    return {
      'vendorId': widget.vendor['vendorId'],
      'vendorName': _nameController.text.trim(),
      'phone': _contactController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'vatNumber': _vatNumberController.text.trim(),
      'maximumCredit': double.tryParse(_maximumCreditController.text) ?? 0.0,
      'currentCredit': double.tryParse(_creditLimitController.text) ?? 0.0,
      'notes': _notesController.text.trim(),
      'status': widget.vendor['status'] ?? 'Active',
      'dateAdded': widget.vendor['dateAdded']?.toString() ?? DateTime.now().toIso8601String(),
      'totalPurchases': widget.vendor['totalPurchases'] ?? 0.0,
      'lastPurchaseDate': widget.vendor['lastPurchaseDate'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Edit Vendor'),
          const Spacer(),
          if (_isSaving)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Saving...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          else if (_getCurrentState() != _lastSavedState)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.edit, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Modified',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Saved',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Vendor Name *',
                validator: (value) => value?.trim().isEmpty == true ? 'Please enter vendor name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number *',
                hintText: '+973 1234 5678',
                keyboardType: TextInputType.phone,
                validator: (value) => value?.trim().isEmpty == true ? 'Please enter contact number' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address *',
                hintText: 'vendor@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'Please enter email address';
                  if (value != null && (!value.contains('@') || !value.contains('.'))) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                hintText: 'e.g., Manama',
                prefixIcon: Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _countryController,
                label: 'Country',
                hintText: 'e.g., Bahrain',
                prefixIcon: Icons.flag,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _vatNumberController,
                label: 'VAT Number',
                hintText: 'e.g., VAT123456789',
                prefixIcon: Icons.numbers,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _maximumCreditController,
                label: 'Maximum Credit (BHD)',
                hintText: '0.000',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter a valid maximum credit amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _creditLimitController,
                label: 'Current Credit (BHD)',
                hintText: '0.000',
                prefixIcon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter a valid current credit amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: 'Notes (optional)',
                hintText: 'Additional information about this vendor',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              // Force save any pending changes
              _debounceTimer?.cancel();
              await _autoSave();
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save & Close'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}

// Inline editable field widget for real-time editing
class InlineEditableField extends StatefulWidget {
  final String initialValue;
  final TextStyle? style;
  final Function(String) onSave;
  final TextInputType? keyboardType;
  final int maxLines;

  const InlineEditableField({
    super.key,
    required this.initialValue,
    this.style,
    required this.onSave,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<InlineEditableField> createState() => _InlineEditableFieldState();
}

class _InlineEditableFieldState extends State<InlineEditableField> {
  late TextEditingController _controller;
  bool _isEditing = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_controller.text.trim() != widget.initialValue.trim()) {
        widget.onSave(_controller.text.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditing = true;
        });
      },
      child: _isEditing
          ? TextField(
              controller: _controller,
              style: widget.style,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              onSubmitted: (value) {
                setState(() {
                  _isEditing = false;
                });
                if (value.trim() != widget.initialValue.trim()) {
                  widget.onSave(value.trim());
                }
              },
              onTapOutside: (event) {
                setState(() {
                  _isEditing = false;
                });
                if (_controller.text.trim() != widget.initialValue.trim()) {
                  widget.onSave(_controller.text.trim());
                }
              },
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _controller.text.isEmpty ? 'Tap to edit' : _controller.text,
                    style: widget.style?.copyWith(
                      color: _controller.text.isEmpty ? Colors.grey : widget.style?.color,
                    ),
                    maxLines: widget.maxLines,
                    overflow: widget.maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
    );
  }
}
