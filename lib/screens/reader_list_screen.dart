import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../state/book_list_notifier.dart' show LoadStatus;
import '../state/reader_list_notifier.dart';
import '../widgets/debounce_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class ReaderListScreen extends StatefulWidget {
  final Map<String, String> queryParams;

  const ReaderListScreen({super.key, required this.queryParams});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromParams());
  }

  @override
  void didUpdateWidget(covariant ReaderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryParams != widget.queryParams) _syncFromParams();
  }

  void _syncFromParams() {
    final query = ReaderQuery.fromQueryParams(widget.queryParams);
    context.read<ReaderListNotifier>().setQuerySilently(query);
  }

  void _updateUrl(ReaderQuery next) {
    context.go(Uri(path: '/readers', queryParameters: next.toQueryParams()).toString());
  }

  void _confirmDeleteSelected(BuildContext context, ReaderListNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить выбранных читателей (${notifier.selected.length})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteSelected();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReaderListNotifier>();
    final query = notifier.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Добавить читателя',
            onPressed: () => context.go('/readers/new'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DebounceSearchField(
                        initialValue: query.search,
                        hintText: 'Поиск по ФИО, email, номеру билета...',
                        onChanged: (v) => _updateUrl(query.copyWith(search: v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Показать удалённых'),
                      selected: query.includeDeleted,
                      onSelected: (v) => _updateUrl(query.copyWith(includeDeleted: v)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (notifier.hasSelection)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Выбрано: ${notifier.selected.length}'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _confirmDeleteSelected(context, notifier),
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить выбранных'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.loading => const Center(child: CircularProgressIndicator()),
              LoadStatus.error => Center(child: Text(notifier.error ?? 'Ошибка')),
              LoadStatus.idle || LoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Читатели не найдены')),
              _ => EntityTable<Reader>(
                  items: notifier.result.items,
                  idOf: (r) => r.id,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onSelectAll: (val) => notifier.selectAll(val ?? false),
                  sortField: notifier.query.sortField,
                  sortAscending: notifier.query.sortAscending,
                  onSort: (field) {
                    final asc = field == notifier.query.sortField ? !notifier.query.sortAscending : true;
                    _updateUrl(notifier.query.copyWith(sortField: field, sortAscending: asc));
                  },
                  columns: [
                    TableColumnSpec(
                      label: 'ФИО',
                      sortField: 'fullName',
                      build: (r) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.fullName,
                            style: TextStyle(
                              decoration: r.isDeleted ? TextDecoration.lineThrough : null,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(r.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Email',
                      build: (r) => Text(r.email),
                    ),
                    TableColumnSpec(
                      label: 'Читательский билет',
                      build: (r) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: r.card.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(r.card.cardNumber),
                        ],
                      ),
                    ),
                  ],
                  actions: (r) => [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Редактировать',
                      onPressed: () => context.go('/readers/${r.id}/edit'),
                    ),
                    if (r.isDeleted)
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        tooltip: 'Восстановить',
                        onPressed: () => notifier.restore(r.id),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Логическое удаление',
                        onPressed: () => notifier.softDelete(r.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Физическое удаление',
                      onPressed: () => notifier.hardDelete(r.id),
                    ),
                  ],
                ),
            },
          ),
          PaginationBar(
            page: notifier.result.page,
            size: notifier.result.size,
            total: notifier.result.total,
            totalPages: notifier.result.totalPages,
            onPageChanged: (newPage) => _updateUrl(query.copyWith(page: newPage)),
            onSizeChanged: (newSize) => _updateUrl(query.copyWith(size: newSize, page: 1)),
          ),
        ],
      ),
    );
  }
}