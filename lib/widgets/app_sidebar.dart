import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/routes/app_routes.dart';
import '../utils/app_assets.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.green[900],
      child: Column(
        children: [
          // Logo and app name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                AppAssets.nexoraLogoRight,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to original design if image fails to load
                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.cut,
                            color: Colors.green[900],
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),         
          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.green[800],
          ),
          
          // Navigation links
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard
                _buildNavItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  '/',
                  currentRoute == '/',
                ),
                
                // Orders
                _buildNavGroup(
                  'Orders',
                  [
                    _buildNavItem(
                      context,
                      'Create New Sale',
                      Icons.add_circle_outline,
                      AppRoutes.newOrder,
                      currentRoute == AppRoutes.newOrder,
                    ),
                    _buildNavItem(
                      context,
                      'All Orders',
                      Icons.list_alt,
                      AppRoutes.allOrders,
                      currentRoute == AppRoutes.allOrders,
                    ),
                    _buildNavItem(
                      context,
                      'Returned Items',
                      Icons.assignment_return,
                      AppRoutes.returnedItems,
                      currentRoute == AppRoutes.returnedItems,
                    ),
                  ],
                ),
                
                // Finance
                _buildNavGroup(
                  'Finance',
                  [
                    _buildNavItem(
                      context,
                      'Invoices',
                      Icons.receipt,
                      AppRoutes.invoices,
                      currentRoute == AppRoutes.invoices,
                    ),
                    _buildNavItem(
                      context,
                      'Expenses',
                      Icons.money_off,
                      AppRoutes.expenses,
                      currentRoute == AppRoutes.expenses,
                    ),
                  ],
                ),
                
                // Other menu items
                _buildNavItem(
                  context,
                  'Inventory Items',
                  Icons.inventory_2,
                  AppRoutes.inventoryItems,
                  currentRoute == AppRoutes.inventoryItems,
                ),
                _buildNavItem(
                  context,
                  'Purchase Items',
                  Icons.shopping_cart,
                  AppRoutes.purchaseItems,
                  currentRoute == AppRoutes.purchaseItems,
                ),
                _buildNavItem(
                  context,
                  'Vendors',
                  Icons.store,
                  AppRoutes.vendors,
                  currentRoute == AppRoutes.vendors,
                ),
                _buildNavItem(
                  context,
                  'Accounts',
                  Icons.account_balance,
                  AppRoutes.accounts,
                  currentRoute == AppRoutes.accounts,
                ),
                _buildNavItem(
                  context,
                  'Settings',
                  Icons.settings,
                  AppRoutes.settings,
                  currentRoute == AppRoutes.settings,
                ),
                
              ],
            ),
          ),
          
          // User section at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[800],
              border: Border(
                top: BorderSide(
                  color: Colors.green[700]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Text(
                    'JS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Smith',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Owner',
                        style: TextStyle(
                          color: Colors.green[100],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Logout button
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // Logout logic
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          context.go(route);   // This is the key navigation line
        }
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[800] : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: Colors.white,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : Colors.green[100],
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.green[100],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.green[200],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}