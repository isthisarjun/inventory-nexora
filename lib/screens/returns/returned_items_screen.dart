import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../services/excel_service.dart';

import 'package:go_router/go_router.dart';

class ReturnedItemsScreen extends StatefulWidget {
  const ReturnedItemsScreen({super.key});

  @override
  State<ReturnedItemsScreen> createState() => _ReturnedItemsScreenState();
}

class _ReturnedItemsScreenState extends State<ReturnedItemsScreen> {
  List<List<Data?>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  Future<void> _loadReturns() async {
    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/returns_log.xlsx';
      final file = File(filePath);
      if (!await file.exists()) {
        // If file doesn't exist, create it with headers
        final excel = ExcelService.instance.initializeReturnsLogExcelFile();
        await file.writeAsBytes(excel.encode()!);
        setState(() { _rows = []; _isLoading = false; });
        return;
      }
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Returns'];
      setState(() {
        _rows = sheet.rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _rows = []; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/'),
        ),
        title: const Text('Returned Items'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty || _rows.length <= 1
              ? const Center(child: Text('No returned items found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _rows.first
                        .map((cell) => DataColumn(
                              label: Text(
                                cell?.value.toString() ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ))
                        .toList(),
                    rows: _rows
                        .skip(1)
                        .map((row) => DataRow(
                              cells: row
                                  .map((cell) => DataCell(
                                        Text(cell?.value.toString() ?? ''),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
    );
  }
}
