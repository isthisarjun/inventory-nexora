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

  List<Map<String, dynamic>> get _filteredVendors {
    if (_searchQuery.isEmpty) return _vendors;
    final q = _searchQuery.toLowerCase();
    return _vendors.where((v) {
      final name = (v['vendorName'] ?? '').toString().toLowerCase();
      final email = (v['email'] ?? '').toString().toLowerCase();
      final phone = (v['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

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

  void _showEditVendorDialog(Map<String, dynamic> vendor) {
    showDialog(
      context: context,
      builder: (context) => EditVendorDialog(
        vendor: vendor,
        excelService: _excelService,
        onVendorUpdated: _loadVendors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
          tooltip: 'Back to Home',
        ),
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
                // Header with gradient summary
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            // Total Vendors tile
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.people, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_vendors.where((v) => v['status'] == 'Active').length}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Text(
                                          'Active Vendors',
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Total Credit tile
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FutureBuilder<double>(
                                            future: _calculateTotalActiveCredit(),
                                            builder: (context, snapshot) => Text(
                                              'BHD ${(snapshot.data ?? 0.0).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Text(
                                            'Total Credit',
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: const InputDecoration(
                              hintText: 'Search vendors by name, email, or phone...',
                              prefixIcon: Icon(Icons.search, color: Color(0xFF4CAF50)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

    final initials = vendorName.trim().isNotEmpty
        ? vendorName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9)),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToVendorDashboard(vendorName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar with initials
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasActiveCredit)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Credit: BHD ${creditAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          const Text(
                            'No outstanding credit',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Edit button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF1976D2), size: 20),
                      onPressed: () => _showEditVendorDialog(vendor),
                      tooltip: 'Edit Vendor',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
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

// ─── EditVendorDialog ─────────────────────────────────────────────────────────

class EditVendorDialog extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final ExcelService excelService;
  final VoidCallback onVendorUpdated;

  const EditVendorDialog({
    super.key,
    required this.vendor,
    required this.excelService,
    required this.onVendorUpdated,
  });

  @override
  State<EditVendorDialog> createState() => _EditVendorDialogState();
}

class _EditVendorDialogState extends State<EditVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _vatNumberController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendor['vendorName'] ?? '');
    _contactController = TextEditingController(text: widget.vendor['phone'] ?? '');
    _emailController = TextEditingController(text: widget.vendor['email'] ?? '');
    _addressController = TextEditingController(text: widget.vendor['address'] ?? '');
    _cityController = TextEditingController(text: widget.vendor['city'] ?? '');
    _countryController = TextEditingController(text: widget.vendor['country'] ?? '');
    _vatNumberController = TextEditingController(text: widget.vendor['vatNumber'] ?? '');
    _creditLimitController = TextEditingController(
      text: widget.vendor['currentCredit']?.toString() ?? '0',
    );
    _notesController = TextEditingController(text: widget.vendor['notes'] ?? '');
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
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updatedVendor = {
        'vendorId': widget.vendor['vendorId'],
        'vendorName': _nameController.text.trim(),
        'phone': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'vatNumber': _vatNumberController.text.trim(),
        'maximumCredit': widget.vendor['maximumCredit'] ?? 0.0,
        'currentCredit': double.tryParse(_creditLimitController.text) ?? 0.0,
        'notes': _notesController.text.trim(),
        'status': widget.vendor['status'] ?? 'Active',
        'dateAdded': widget.vendor['dateAdded'] ?? DateTime.now().toIso8601String(),
        'totalPurchases': widget.vendor['totalPurchases'] ?? 0.0,
        'lastPurchaseDate': widget.vendor['lastPurchaseDate'] ?? '',
      };
      final success = await widget.excelService.updateVendorInExcel(updatedVendor);
      if (!mounted) return;
      if (success) {
        widget.onVendorUpdated();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update vendor.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
              child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8F5E9)),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          labelStyle: const TextStyle(color: Color(0xFF616161), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 680),
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
            // Gradient Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
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
                    child: const Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Vendor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.vendor['vendorName'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSection('Basic Information', Icons.business, [
                        _buildFormField(_nameController, 'Vendor Name', Icons.store,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null),
                        _buildFormField(_contactController, 'Phone', Icons.phone,
                            keyboardType: TextInputType.phone),
                        _buildFormField(_emailController, 'Email', Icons.email,
                            keyboardType: TextInputType.emailAddress),
                        _buildFormField(_vatNumberController, 'VAT Number', Icons.receipt_long),
                      ]),
                      _buildSection('Location', Icons.location_on, [
                        _buildFormField(_addressController, 'Address', Icons.map_outlined),
                        _buildFormField(_cityController, 'City', Icons.location_city),
                        _buildFormField(_countryController, 'Country', Icons.flag_outlined),
                      ]),
                      _buildSection('Financial', Icons.account_balance_wallet, [
                        _buildFormField(_creditLimitController, 'Credit Limit', Icons.credit_card,
                            keyboardType: TextInputType.number),
                        _buildFormField(_notesController, 'Notes', Icons.note_outlined),
                      ]),
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
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFF4CAF50))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 18),
                                SizedBox(width: 8),
                                Text('Save Changes',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
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

// ─── AddVendorDialog ──────────────────────────────────────────────────────────

class AddVendorDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onVendorAdded;

  const AddVendorDialog({
    super.key,
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
  final _notesController = TextEditingController();
  bool _isSaving = false;

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
    _notesController.dispose();
    super.dispose();
  }

  String _generateVendorId(String name) {
    final cleanName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'vendor_${cleanName}_$timestamp';
  }

  void _saveVendor() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final vendor = {
        'vendorId': _generateVendorId(_nameController.text.trim()),
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
        'dateAdded': DateTime.now().toIso8601String(),
        'totalPurchases': 0.0,
        'lastPurchaseDate': '',
      };
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onVendorAdded(vendor);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
              child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8F5E9)),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          labelStyle: const TextStyle(color: Color(0xFF616161), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        width: 520,
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
            // Gradient Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
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
                    child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Vendor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fill in the vendor details below',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSection('Basic Information', Icons.business, [
                        _buildFormField(_nameController, 'Vendor Name *', Icons.store,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null),
                        _buildFormField(_contactController, 'Phone', Icons.phone,
                            keyboardType: TextInputType.phone),
                        _buildFormField(_emailController, 'Email', Icons.email,
                            keyboardType: TextInputType.emailAddress),
                        _buildFormField(_vatNumberController, 'VAT Number', Icons.receipt_long),
                      ]),
                      _buildSection('Location', Icons.location_on, [
                        _buildFormField(_addressController, 'Address', Icons.map_outlined),
                        _buildFormField(_cityController, 'City', Icons.location_city),
                        _buildFormField(_countryController, 'Country', Icons.flag_outlined),
                      ]),
                      _buildSection('Financial', Icons.account_balance_wallet, [
                        _buildFormField(_maximumCreditController, 'Maximum Credit',
                            Icons.credit_score,
                            keyboardType: TextInputType.number),
                        _buildFormField(_creditLimitController, 'Current Credit',
                            Icons.credit_card,
                            keyboardType: TextInputType.number),
                        _buildFormField(_notesController, 'Notes', Icons.note_outlined),
                      ]),
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
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFF4CAF50))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveVendor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 18),
                                SizedBox(width: 8),
                                Text('Add Vendor',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
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

// ─── InlineEditableField ──────────────────────────────────────────────────────

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
