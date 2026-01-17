import 'package:tailor_v3/screens/returns/returned_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_v3/screens/splash_screen.dart';
import 'package:tailor_v3/screens/finance/add_expense_screen.dart';
import 'package:tailor_v3/screens/finance/invoices_screen.dart';
import 'package:tailor_v3/screens/finance/invoice_details_screen.dart';
import 'package:tailor_v3/screens/finance/vat_filing_screen.dart';
import 'package:tailor_v3/screens/inventory/inventory_management_screen.dart';
import 'package:tailor_v3/screens/inventory/inventory_items_screen.dart';
import 'package:tailor_v3/screens/inventory/stock_purchase_history_screen.dart';
import 'package:tailor_v3/screens/inventory/vendor_management_screen.dart';
import 'package:tailor_v3/screens/vendors/vendor_dashboard_screen.dart';
import 'package:tailor_v3/screens/purchase/purchase_items_screen.dart';
import 'package:tailor_v3/screens/accounts/accounts_screen.dart';
import 'package:tailor_v3/screens/accounts/supplier_accounts_screen.dart';
import 'package:tailor_v3/screens/accounts/all_accounts_screen.dart';

import 'package:tailor_v3/screens/transactions/transactions_screen.dart';
import 'package:tailor_v3/screens/expenses/expenses_screen.dart';
import 'package:tailor_v3/screens/orders/new_order_screen.dart';
import 'package:tailor_v3/screens/orders/all_orders_screen.dart';
import 'package:tailor_v3/screens/orders/order_summary_screen.dart';
import 'package:tailor_v3/screens/orders/work_details_screen.dart';

// Import your screens here
import '../screens/home_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Defines all route paths used in the application
class AppRoutes {
  // Main routes
  static const String home = '/home';
  static const String allOrders = '/all-orders';
  static const String inventory = '/inventory';
  static const String inventoryItems = '/inventory-items';
  static const String stockPurchaseHistory = '/stock-purchase-history';
  static const String purchaseItems = '/purchase-items';
  static const String vendors = '/vendors';
  static const String invoices = '/invoices';
  static const String settings = '/settings';
  static const String newOrder = '/new-order';
  static const String addExpense = '/expenses/new';
  static const String measurements = '/measurements';
  static const String workDetails = '/work-details';
  static const String splash = '/splash';
  static const String orderSummary = '/order-summary';
  static const String returnedItems = '/returned-items';
  
  // Accounts routes
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String expenses = '/expenses';
  static const String supplierAccounts = '/accounts/suppliers';
  static const String allAccounts = '/accounts/all';
  static const String vatFiling = '/vat-filing';

  static const String invoiceDetails = '/invoice-details';
  
  // Error routes
  static const String notFound = '/404';
}

/// Router configuration and navigation helpers
class AppRouter {
  /// Configure and create the app router
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      routes: [
        // Main routes
        GoRoute(
          path: '/',
          name: 'root',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: AppRoutes.allOrders,
          name: 'allOrders',
          builder: (context, state) => const AllOrdersScreen(),
        ),
        GoRoute(path: AppRoutes.inventory,
          name: 'inventory',
          builder: (context, state) => const InventoryManagementScreen(),
        ),
        GoRoute(path: AppRoutes.inventoryItems,
          name: 'inventoryItems',
          builder: (context, state) => const InventoryItemsScreen(),
        ),
        GoRoute(path: AppRoutes.stockPurchaseHistory,
          name: 'stockPurchaseHistory',
          builder: (context, state) => const StockPurchaseHistoryScreen(),
        ),
        GoRoute(path: AppRoutes.purchaseItems,
          name: 'purchaseItems',
          builder: (context, state) => const PurchaseItemsScreen(),
        ),
        GoRoute(path: AppRoutes.vendors,
          name: 'vendors',
          builder: (context, state) => const VendorManagementScreen(),
        ),
        GoRoute(
          path: '/vendor-dashboard/:vendorName',
          name: 'vendorDashboard',
          builder: (context, state) {
            final vendorName = Uri.decodeComponent(state.pathParameters['vendorName']!);
            return VendorDashboardScreen(vendorName: vendorName);
          },
        ),
        GoRoute(path: AppRoutes.invoices,
          name: 'invoices',
          builder: (context, state) => const InvoicesScreen(),
        ),
        GoRoute(path: AppRoutes.newOrder,
          name: 'newOrder',
          builder: (context, state) => const NewOrderScreen(),
        ),
        GoRoute(path: AppRoutes.addExpense,
          name: 'addExpense',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        GoRoute(path: AppRoutes.workDetails,
          name: 'workDetails',
          builder: (context, state) {
            final customerId = state.uri.queryParameters['customerId'] ?? '';
            final items = state.uri.queryParameters['items'] ?? '';
            final materials = state.uri.queryParameters['materials'] ?? '';
            return WorkDetailsScreen(
              customerId: customerId,
              items: items,
              materials: materials,
            );
          },
        ),
        GoRoute(path: AppRoutes.orderSummary,
          name: 'orderSummary',
          builder: (context, state) {
            final customerId = state.uri.queryParameters['customerId'] ?? '';
            final items = state.uri.queryParameters['items'] ?? '';
            final materials = state.uri.queryParameters['materials'] ?? '';
            final description = state.uri.queryParameters['description'] ?? '';
            final labourCost = state.uri.queryParameters['labourCost'] ?? '';
            final dueDate = state.uri.queryParameters['dueDate'] ?? '';
            final includeVat = state.uri.queryParameters['includeVat'] != 'false'; // Default true
            return OrderSummaryScreen(
              customerId: customerId,
              items: items,
              materials: materials,
              description: description,
              labourCost: labourCost,
              dueDate: dueDate,
              includeVat: includeVat,
            );
          },
        ),

        // Accounts routes
        GoRoute(
          path: AppRoutes.accounts,
          name: 'accounts',
          builder: (context, state) => const AccountsScreen(),
        ),
        GoRoute(
          path: AppRoutes.transactions,
          name: 'transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          name: 'expenses',
          builder: (context, state) => const ExpensesScreen(),
        ),
        GoRoute(
          path: AppRoutes.supplierAccounts,
          name: 'supplierAccounts',
          builder: (context, state) => const SupplierAccountsScreen(),
        ),
        GoRoute(
          path: AppRoutes.allAccounts,
          name: 'allAccounts',
          builder: (context, state) => const AllAccountsScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.invoiceDetails}/:orderId',
          name: 'invoiceDetails',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            // For now, we'll pass a mock order. In production, you'd fetch the order by ID
            final mockOrder = {
              'id': orderId,
              'customerName': 'Mock Customer',
              'customerPhone': '+973 1234 5678',
              'orderDate': DateTime.now().toIso8601String(),
              'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'totalCost': '125.000',
              'advanceAmount': '50.000',
              'materialsCost': '45.000',
              'labourCost': '80.000',
              'paymentStatus': 'Pending',
              'items': ['Shirt', 'Trouser'],
            };
            return InvoiceDetailsScreen(order: mockOrder);
          },
        ),
        GoRoute(
          path: AppRoutes.returnedItems,
          name: 'returnedItems',
          builder: (context, state) => const ReturnedItemsScreen(),
        ),
        GoRoute(
          path: AppRoutes.vatFiling,
          name: 'vatFiling',
          builder: (context, state) {
            final filePath = state.extra as String?;
            return VatFilingScreen(initialFilePath: filePath);
          },
        ),
         // Add more routes as you implement the screens
      ],
      
      // Error handling for undefined routes
      errorBuilder: (context, state) {
        debugPrint('Error: [31m${state.error}[0m');
        return const HomeScreen();
      },
    );
  }
  
  /// Navigate to a named route
  static void navigateTo(BuildContext context, String routeName, {Object? extra}) {
    context.goNamed(routeName, extra: extra);
  }
  
  /// Go to a specific path
  static void goTo(BuildContext context, String path) {
    context.go(path);
  }
  
  /// Push a new route onto the stack
  static void pushTo(BuildContext context, String path) {
    context.push(path);
  }
  
  /// Go back to the previous route
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}
