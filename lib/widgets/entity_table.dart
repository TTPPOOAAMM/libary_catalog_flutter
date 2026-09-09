import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<bool?>? onSelectAll;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final void Function(T item)? onTap;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileCards(context);
        }
        return _buildDesktopTable(context);
      },
    );
  }

  Widget _buildMobileCards(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        final isSelected = selected.contains(id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onToggleSelect != null)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSelect!(id),
                      ),
                    Expanded(
                      child: InkWell(
                        onTap: onTap != null ? () => onTap!(item) : null,
                        child: columns.first.build(item),
                      ),
                    ),
                    if (actions != null) Row(mainAxisSize: MainAxisSize.min, children: actions!(item)),
                  ],
                ),
                const Divider(),
                ...columns.skip(1).map((col) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(col.label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          col.build(item),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildDesktopTable(BuildContext context) {
    final sortColIndex = sortField != null
        ? columns.indexWhere((c) => c.sortField == sortField)
        : -1;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center( 
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800), 
            child: DataTable(
              showCheckboxColumn: onToggleSelect != null,
              sortColumnIndex: sortColIndex != -1 ? sortColIndex : null,
              sortAscending: sortAscending,
              onSelectAll: onSelectAll,
              columns: [
                ...columns.map((col) {
                  return DataColumn(
                    label: Text(col.label),
                    numeric: col.numeric,
                    onSort: col.sortField != null && onSort != null
                        ? (_, __) => onSort!(col.sortField!)
                        : null,
                  );
                }),
                if (actions != null) const DataColumn(label: Text('Действия')),
              ],
              rows: items.map((item) {
                final id = idOf(item);
                final isSelected = selected.contains(id);

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: onToggleSelect != null
                      ? (_) => onToggleSelect!(id)
                      : null,
                  cells: [
                    ...columns.map((col) {
                      return DataCell(
                        col.build(item),
                        onTap: onTap != null ? () => onTap!(item) : null,
                      );
                    }),
                    if (actions != null)
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!(item),
                      )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}