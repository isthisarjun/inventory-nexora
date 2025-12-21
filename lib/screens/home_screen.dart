import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_sidebar.dart';
import '../routes/app_routes.dart';
import '../services/excel_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _excelService = ExcelService();
  bool _isInitializing = true;
  
  @override
  void initState() {
    super.initState();
    _initializeTransactionSystem();
  }
  
  /// Initialize the transaction details Excel file
  Future<void> _initializeTransactionSystem() async {
    try {
      await _excelService.initializeTransactionDetailsFile();
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error initializing transaction system: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }
  
  /// Test the transaction system by showing summary
  Future<void> _testTransactionSystem() async {
    try {
      final transactions = await _excelService.loadTransactionsFromExcel();
      final totalProfit = await _excelService.getTotalProfit();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue),
              SizedBox(width: 8),
              Text('Transaction Summary'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Total Transactions: ${transactions.length}'),
                const SizedBox(height: 8),
                Text('💰 Net Profit: ${totalProfit.toStringAsFixed(3)} BHD'),
                const SizedBox(height: 16),
                const Text('Recent Transactions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...transactions.take(5).map((transaction) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          transaction['partyName'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${transaction['amount'] > 0 ? '+' : ''}${transaction['amount']?.toStringAsFixed(2) ?? '0.00'} BHD',
                          style: TextStyle(
                            fontSize: 12,
                            color: transaction['amount'] > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error loading transaction summary: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sidebar
            AppSidebar(
              currentRoute: ModalRoute.of(context)?.settings.name ?? AppRoutes.home,
            ),

            // Main Content - Simplified
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: _isInitializing 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Initializing Transaction System...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.dashboard,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome to Inventory Management System',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use the sidebar to navigate through the application',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '✅ Transaction Details Excel Sheet Initialized',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _testTransactionSystem,
                            icon: const Icon(Icons.assessment),
                            label: const Text('View Transaction Summary'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}