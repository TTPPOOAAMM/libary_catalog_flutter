import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/publisher_repository.dart';
import '../state/book_list_notifier.dart' show LoadStatus;
import '../state/publisher_list_notifier.dart';
import '../widgets/debounce_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class PublisherListScreen extends StatefulWidget {
  final Map<String, String> queryParams;

  const PublisherListScreen({super.key, required this.queryParams});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromParams());
  }

  @override
  void didUpdateWidget(covariant PublisherListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryParams != widget.queryParams) _syncFromParams();
  }

  void _syncFromParams() {
    final query = PublisherQuery.fromQueryParams(widget.queryParams);
    context.read<PublisherListNotifier>().setQuerySilently(query);
  }

  void _updateUrl(PublisherQuery next) {
    context.go(Uri(path: '/publishers', queryParameters: next.toQueryParams())
        .toString());
  }

  Future<void> _deletePublisher(BuildContext context, Publisher p) async {
    final repo = context.read<PublisherRepository>();
    final linkedCount = await repo.countBooksReferencing(p.id);

    if (!context.mounted) return;

    if (linkedCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Отказ в удалении'),
          content: Text(
            'Невозможно удалить издательство "${p.name}". К нему привязано записей в каталоге книг: $linkedCount шт.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    await repo.softDelete(p.id);
    if (context.mounted) {
      context.read<PublisherListNotifier>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PublisherListNotifier>();
    final query = notifier.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Издательства'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'В каталог книг',
          onPressed: () => context.go('/books'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
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
                        hintText: 'Поиск по названию, городу...',
                        onChanged: (v) => _updateUrl(query.copyWith(search: v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: query.includeDeleted,
                      onSelected: (v) =>
                          _updateUrl(query.copyWith(includeDeleted: v)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (notifier.status) {
              LoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              LoadStatus.error =>
                Center(child: Text(notifier.error ?? 'Ошибка')),
              LoadStatus.idle ||
              LoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Издательства не найдены')),
              _ => EntityTable<Publisher>(
                  items: notifier.result.items,
                  idOf: (p) => p.id,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onSelectAll: (val) => notifier.selectAll(val ?? false),
                  sortField: notifier.query.sortField,
                  sortAscending: notifier.query.sortAscending,
                  onSort: (field) {
                    final asc = field == notifier.query.sortField
                        ? !notifier.query.sortAscending
                        : true;
                    _updateUrl(notifier.query
                        .copyWith(sortField: field, sortAscending: asc));
                  },
                  columns: [
                    TableColumnSpec(
                      label: 'Название',
                      sortField: 'name',
                      build: (p) => Text(
                        p.name,
                        style: TextStyle(
                          decoration:
                              p.isDeleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Город',
                      build: (p) => Text(p.city),
                    ),
                  ],
                  actions: (p) => [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Удалить',
                      onPressed: () => _deletePublisher(context, p),
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
            onPageChanged: (newPage) =>
                _updateUrl(query.copyWith(page: newPage)),
            onSizeChanged: (newSize) =>
                _updateUrl(query.copyWith(size: newSize, page: 1)),
          ),
        ],
      ),
    );
  }
}
