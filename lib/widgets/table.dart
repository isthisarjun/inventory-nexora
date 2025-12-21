import 'package:flutter/material.dart';

/// A customizable data table component with various styling options.
class DataTable extends StatelessWidget {
  /// The headers for the table columns.
  final List<TableColumn> columns;
  
  /// The data rows of the table.
  final List<Map<String, dynamic>> data;
  
  /// Callback when a row is tapped.
  final Function(Map<String, dynamic>)? onRowTap;
  
  /// Callback to customize how a cell is rendered.
  final Widget Function(BuildContext, String, dynamic, int, int)? cellBuilder;
  
  /// Whether the table has a border.
  final bool hasBorder;
  
  /// Whether zebra striping is applied to rows.
  final bool zebraStripe;
  
  /// Whether the table is compact (reduced padding).
  final bool isCompact;
  
  /// Whether the table has hover effects on rows.
  final bool hasHover;
  
  /// Whether the headers are sticky.
  final bool stickyHeader;
  
  /// Maximum height of the table with scrolling.
  final double? maxHeight;
  
  /// Whether the table header is visible.
  final bool showHeader;
  
  /// Empty state widget shown when there's no data.
  final Widget? emptyState;
  
  /// Whether the table should be horizontally scrollable.
  final bool horizontalScroll;
  
  /// Border radius of the table.
  final double borderRadius;

  const DataTable({
    super.key,
    required this.columns,
    required this.data,
    this.onRowTap,
    this.cellBuilder,
    this.hasBorder = true,
    this.zebraStripe = true,
    this.isCompact = false,
    this.hasHover = true,
    this.stickyHeader = false,
    this.maxHeight,
    this.showHeader = true,
    this.emptyState,
    this.horizontalScroll = false,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty && emptyState != null) {
      return emptyState!;
    }

    final tableWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _buildHeader(context),
        _buildRows(context),
      ],
    );

    // Apply horizontal scrolling if needed
    Widget resultWidget = horizontalScroll
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tableWidget,
          )
        : tableWidget;

    // Apply max height with vertical scrolling if needed
    if (maxHeight != null) {
      resultWidget = Container(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: SingleChildScrollView(
          child: resultWidget,
        ),
      );
    }

    // Apply border if needed
    if (hasBorder) {
      resultWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: resultWidget,
      );
    }

    return resultWidget;
  }

  Widget _buildHeader(BuildContext context) {
    final headerCells = columns.map((column) {
      return _buildHeaderCell(context, column);
    }).toList();

    final headerRow = Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: hasBorder
            ? Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              )
            : null,
      ),
      child: Row(
        children: headerCells,
      ),
    );

    if (stickyHeader) {
      return Container(
        color: Colors.grey[100],
        child: headerRow,
      );
    }

    return headerRow;
  }

  Widget _buildHeaderCell(BuildContext context, TableColumn column) {
    return Expanded(
      flex: column.flex ?? 1,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isCompact ? 8.0 : 12.0,
        ),
        alignment: column.align?.toAlignment() ?? Alignment.centerLeft,
        child: column.header,
      ),
    );
  }

  Widget _buildRows(BuildContext context) {
    return Column(
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final rowData = entry.value;

        final isEvenRow = index % 2 == 0;
        final backgroundColor = zebraStripe && !isEvenRow
            ? Colors.grey[50]
            : Colors.white;

        return Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onRowTap != null ? () => onRowTap!(rowData) : null,
            child: Container(
              decoration: BoxDecoration(
                border: hasBorder && index < data.length - 1
                    ? Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      )
                    : null,
              ),
              child: Row(
                children: columns.asMap().entries.map((columnEntry) {
                  final columnIndex = columnEntry.key;
                  final column = columnEntry.value;

                  final cellValue = rowData[column.accessorKey];

                  return _buildCell(
                    context,
                    column,
                    cellValue,
                    index,
                    columnIndex,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCell(
    BuildContext context,
    TableColumn column,
    dynamic value,
    int rowIndex,
    int columnIndex,
  ) {
    // Use custom cell builder if provided
    if (cellBuilder != null) {
      return Expanded(
        flex: column.flex ?? 1,
        child: cellBuilder!(
          context,
          column.accessorKey,
          value,
          rowIndex,
          columnIndex,
        ),
      );
    }

    // Use column cell builder if provided
    if (column.cellBuilder != null) {
      return Expanded(
        flex: column.flex ?? 1,
        child: column.cellBuilder!(context, value, rowIndex),
      );
    }

    // Default cell rendering
    final cellContent = value != null ? value.toString() : '';

    return Expanded(
      flex: column.flex ?? 1,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isCompact ? 8.0 : 12.0,
        ),
        alignment: column.align?.toAlignment() ?? Alignment.centerLeft,
        child: Text(
          cellContent,
          style: TextStyle(
            color: Colors.grey[800],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Column alignment options for the table.
enum ColumnAlign {
  left,
  center,
  right,
}

extension ColumnAlignExtension on ColumnAlign {
  Alignment toAlignment() {
    switch (this) {
      case ColumnAlign.left:
        return Alignment.centerLeft;
      case ColumnAlign.center:
        return Alignment.center;
      case ColumnAlign.right:
        return Alignment.centerRight;
    }
  }
}

/// Definition for a table column.
class TableColumn {
  /// Unique key to access data from the row object.
  final String accessorKey;
  
  /// Header widget for the column.
  final Widget header;
  
  /// Flex value for the column width.
  final int? flex;
  
  /// Alignment of the column content.
  final ColumnAlign? align;
  
  /// Custom cell builder function.
  final Widget Function(BuildContext, dynamic, int)? cellBuilder;

  TableColumn({
    required this.accessorKey,
    required this.header,
    this.flex = 1,
    this.align,
    this.cellBuilder,
  });
}

/// A simple empty state widget for tables.
class TableEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const TableEmptyState({
    super.key,
    this.message = 'No data available',
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 48.0,
              color: Colors.grey[400],
            ),
          if (icon != null) const SizedBox(height: 16.0),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}