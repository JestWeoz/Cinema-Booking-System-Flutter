import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class AppTableColumn {
  final String label;
  final TableColumnWidth width;

  const AppTableColumn({
    required this.label,
    this.width = const FlexColumnWidth(),
  });
}

class AppTableRowData {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const AppTableRowData({
    required this.cells,
    this.onTap,
  });
}

class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRowData> rows;
  final Widget? empty;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return empty ?? const SizedBox.shrink();
    }

    final widths = <int, TableColumnWidth>{
      for (var index = 0; index < columns.length; index++) index: columns[index].width,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Table(
        columnWidths: widths,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            children: columns
                .map(
                  (column) => Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      column.label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...rows.map(
            (row) => TableRow(
              children: row.cells
                  .map(
                    (cell) => InkWell(
                      onTap: row.onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: cell,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
