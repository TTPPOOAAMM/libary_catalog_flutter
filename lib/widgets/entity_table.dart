import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    this.sortField,
    this.numeric = false,
    required this.build,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final void Function(int id) onToggleSelect;
  final void Function(bool? selectAll) onSelectAll;
  final String sortField;
  final bool sortAscending;
  final void Function(String field) onSort;
  final List<TableColumnSpec<T>> columns;
  final List<Widget> Function(T item)? actions;
  final void Function(T item)? onTap;

  const EntityTable({
    super.key,
    required this.items,
    required this.idOf,
    required this.selected,
    required this.onToggleSelect,
    required this.onSelectAll,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.columns,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Данные отсутствуют',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // На экранах < 768 px показываем адаптивные карточки
        if (constraints.maxWidth < 768) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = idOf(item);
              final isChecked = selected.contains(id);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap != null ? () => onTap!(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (_) => onToggleSelect(id),
                            ),
                            Expanded(
                              child: DefaultTextStyle(
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: columns.first.build(item),
                              ),
                            ),
                            if (actions != null)
                              Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: actions!(item)),
                          ],
                        ),
                        const Divider(height: 12),
                        ...columns.skip(1).map(
                              (col) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        '${col.label}:',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Colors.grey),
                                      ),
                                    ),
                                    Expanded(
                                      child: DefaultTextStyle(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        child: col.build(item),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        // На десктопе (>= 768 px) - двумерная таблица
        final allSelected = selected.length == items.length && items.isNotEmpty;

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allSelected,
                        onChanged: onSelectAll,
                      ),
                    ),
                    ...columns.map(
                      (col) => DataColumn(
                        label: Text(col.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        numeric: col.numeric,
                        onSort: col.sortField != null
                            ? (_, __) => onSort(col.sortField!)
                            : null,
                      ),
                    ),
                    if (actions != null)
                      const DataColumn(label: Text('Действия')),
                  ],
                  rows: items.map((item) {
                    final id = idOf(item);
                    return DataRow(
                      selected: selected.contains(id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: selected.contains(id),
                            onChanged: (_) => onToggleSelect(id),
                          ),
                        ),
                        ...columns.map(
                          (col) => DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: DefaultTextStyle(
                                style: Theme.of(context).textTheme.bodyMedium!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                child: col.build(item),
                              ),
                            ),
                            onTap: onTap != null ? () => onTap!(item) : null,
                          ),
                        ),
                        if (actions != null)
                          DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions!(item))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
