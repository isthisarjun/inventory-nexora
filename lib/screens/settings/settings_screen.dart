import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tailor_v3/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // User settings
  final Map<String, dynamic> _userSettings = {
    'profile': {
      'name': 'John Smith',
      'email': 'john.smith@example.com',
      'role': 'Owner',
    },
    'business': {
      'businessName': 'Smith Tailoring',
      'phone': '+1 234 567 8900',
      'address': '123 Main Street, New York, NY 10001',
      'taxId': 'TAX-123456789',
    },
    'notifications': {
      'orderUpdates': true,
      'customerMessages': true,
      'paymentReminders': true,
      'marketingEmails': false,
    },
    'appearance': {
      'theme': 'light',
      'density': 'comfortable',
    },
    'security': {
      'twoFactorAuth': false,
      'passwordLastChanged': '2025-03-15',
    },
  };
  
  // Theme options
  final Map<String, bool> _themeOptions = {
    'light': true,
    'dark': false,
    'system': false,
  };
  
  // Backup and data
  bool _isBackingUp = false;
  String? _lastBackupDate = '2025-06-10 09:30 AM';
  
  // App information
  final String _appVersion = '1.2.0';
  final String _buildNumber = '120';
  
  Future<void> _backupData() async {
    setState(() {
      _isBackingUp = true;
    });
    
    // Simulate backup process
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isBackingUp = false;
      _lastBackupDate = DateTime.now().toString();
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data backup completed successfully'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
  
  void _toggleTheme(String theme) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    setState(() {
      for (final key in _themeOptions.keys) {
        _themeOptions[key] = key == theme;
      }
      _userSettings['appearance']['theme'] = theme;
    });
    
    // Update the actual app theme
    switch (theme) {
      case 'light':
        themeProvider.setLightTheme();
        break;
      case 'dark':
        themeProvider.setDarkTheme();
        break;
      case 'system':
        themeProvider.setSystemTheme();
        break;
    }
  }
  
  void _signOut() {
    // Sign out logic would go here
    // Navigate to login screen
    context.go('/login');
    
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been signed out'),
      ),
    );
  }
  
  void _toggleNotification(String key, bool value) {
    setState(() {
      _userSettings['notifications'][key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Sync theme options with current theme provider state
        _syncThemeOptions(themeProvider);
        
        return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to home screen
            context.go('/');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _buildSectionTitle('Profile'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        _userSettings['profile']['name'].substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // User info
                    Text(
                      _userSettings['profile']['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userSettings['profile']['email'],
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _userSettings['profile']['role'],
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Edit profile button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      onPressed: () {
                        // Navigate to edit profile screen
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Business information
            _buildSectionTitle('Business Information'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingItem(
                      'Business Name',
                      _userSettings['business']['businessName'],
                      Icons.business,
                      editable: true,
                    ),
                    const Divider(),
                    _buildSettingItem(
                      'Phone',
                      _userSettings['business']['phone'],
                      Icons.phone,
                      editable: true,
                    ),
                    const Divider(),
                    _buildSettingItem(
                      'Address',
                      _userSettings['business']['address'],
                      Icons.location_on,
                      editable: true,
                    ),
                    const Divider(),
                    _buildSettingItem(
                      'Tax ID',
                      _userSettings['business']['taxId'],
                      Icons.receipt,
                      editable: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Notifications
            _buildSectionTitle('Notifications'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSwitchItem(
                      'Order Updates',
                      'Get notified about order status changes',
                      Icons.shopping_bag,
                      _userSettings['notifications']['orderUpdates'],
                      (value) => _toggleNotification('orderUpdates', value),
                    ),
                    const Divider(),
                    _buildSwitchItem(
                      'Customer Messages',
                      'Receive notifications for new messages',
                      Icons.message,
                      _userSettings['notifications']['customerMessages'],
                      (value) => _toggleNotification('customerMessages', value),
                    ),
                    const Divider(),
                    _buildSwitchItem(
                      'Payment Reminders',
                      'Get alerts for upcoming and overdue payments',
                      Icons.payment,
                      _userSettings['notifications']['paymentReminders'],
                      (value) => _toggleNotification('paymentReminders', value),
                    ),
                    const Divider(),
                    _buildSwitchItem(
                      'Marketing Emails',
                      'Receive news and promotional updates',
                      Icons.email,
                      _userSettings['notifications']['marketingEmails'],
                      (value) => _toggleNotification('marketingEmails', value),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Appearance
            _buildSectionTitle('Appearance'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Theme selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildThemeOption(
                          'Light',
                          Icons.light_mode,
                          'light',
                          _themeOptions['light']!,
                        ),
                        _buildThemeOption(
                          'Dark',
                          Icons.dark_mode,
                          'dark',
                          _themeOptions['dark']!,
                        ),
                        _buildThemeOption(
                          'System',
                          Icons.settings_suggest,
                          'system',
                          _themeOptions['system']!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Backup and Data
            _buildSectionTitle('Backup & Data'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_lastBackupDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.backup,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last backup: $_lastBackupDate',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    _isBackingUp
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.backup),
                                label: const Text('Backup Data'),
                                onPressed: _backupData,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.restore),
                                label: const Text('Restore Data'),
                                onPressed: () {
                                  // Restore data logic
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Restoring data...')),
                                  );
                                },
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete All Data',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[300]!),
                      ),
                      onPressed: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete All Data?'),
                            content: const Text(
                              'This action cannot be undone. All your data will be permanently deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Data deletion initiated...')),
                                  );
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Information
            _buildSectionTitle('App Information'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoItem('App Version', _appVersion),
                    const Divider(),
                    _buildInfoItem('Build Number', _buildNumber),
                    const Divider(),
                    InkWell(
                      onTap: () {
                        // Open privacy policy
                      },
                      child: _buildInfoItem('Privacy Policy', 'View'),
                    ),
                    const Divider(),
                    InkWell(
                      onTap: () {
                        // Open terms of service
                      },
                      child: _buildInfoItem('Terms of Service', 'View'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.red[300]!),
                ),
                onPressed: _signOut,
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
        ); // Close Scaffold
      }, // Close Consumer builder
    ); // Close Consumer
  }
  
  // Sync theme options with current theme provider state
  void _syncThemeOptions(ThemeProvider themeProvider) {
    String currentTheme = 'light';
    if (themeProvider.isDarkMode) {
      currentTheme = 'dark';
    } else if (themeProvider.isSystemMode) {
      currentTheme = 'system';
    }
    
    for (final key in _themeOptions.keys) {
      _themeOptions[key] = key == currentTheme;
    }
    _userSettings['appearance']['theme'] = currentTheme;
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem(
    String label,
    String value,
    IconData icon, {
    bool editable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                // Edit logic
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchItem(
    String label,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeOption(
    String label,
    IconData icon,
    String value,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _toggleTheme(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green[700] : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}