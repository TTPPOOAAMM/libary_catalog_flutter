import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../state/book_list_notifier.dart' show LoadStatus;
import '../widgets/debounce_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class AuthorListScreen extends StatefulWidget {
  final Map<String, String> queryParams;

  const AuthorListScreen({super.key, required this.queryParams});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromParams());
  }

  @override
  void didUpdateWidget(covariant AuthorListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryParams != widget.queryParams) _syncFromParams();
  }

  void _syncFromParams() {
    final query = AuthorQuery.fromQueryParams(widget.queryParams);
    context.read<AuthorListNotifier>().setQuerySilently(query);
  }

  void _updateUrl(AuthorQuery next) {
    context.go(Uri(path: '/authors', queryParameters: next.toQueryParams())
        .toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final query = notifier.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список авторов'),
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
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: DebounceSearchField(
                        initialValue: query.search,
                        hintText: 'Поиск по фамилии, стране...',
                        onChanged: (v) => _updateUrl(query.copyWith(search: v)),
                      ),
                    ),
                    DropdownButton<String?>(
                      value: query.country,
                      hint: const Text('Все страны'),
                      items: const [
                        DropdownMenuItem(
                            value: null, child: Text('Все страны')),
                        DropdownMenuItem(
                            value: 'Россия', child: Text('Россия')),
                        DropdownMenuItem(
                            value: 'Великобритания',
                            child: Text('Великобритания')),
                        DropdownMenuItem(value: 'США', child: Text('США')),
                        DropdownMenuItem(
                            value: 'Франция', child: Text('Франция')),
                      ],
                      onChanged: (v) => _updateUrl(query.copyWith(country: v)),
                    ),
                    FilterChip(
                      label: const Text('Показать удалённых'),
                      selected: query.includeDeleted,
                      onSelected: (v) =>
                          _updateUrl(query.copyWith(includeDeleted: v)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (notifier.hasSelection)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text('Выбрано: ${notifier.selected.length}'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: notifier.deleteSelected,
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить выбранных'),
                  ),
                ],
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
                const Center(child: Text('Авторы не найдены')),
              _ => EntityTable<Author>(
                  items: notifier.result.items,
                  idOf: (a) => a.id,
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
                  onTap: (a) => context.go('/authors/${a.id}'),
                  columns: [
                    TableColumnSpec(
                      label: 'Фамилия, Имя',
                      sortField: 'lastName',
                      build: (a) => Text(a.fullName,
                          style: TextStyle(
                              decoration: a.isDeleted
                                  ? TextDecoration.lineThrough
                                  : null)),
                    ),
                    TableColumnSpec(
                      label: 'Страна',
                      sortField: 'country',
                      build: (a) => Text(a.country),
                    ),
                    TableColumnSpec(
                      label: 'Год рождения',
                      sortField: 'birthYear',
                      numeric: true,
                      build: (a) => Text('${a.birthYear}'),
                    ),
                  ],
                  actions: (a) => [
                    if (a.isDeleted)
                      IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () => notifier.restore(a.id))
                    else
                      IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => notifier.softDelete(a.id)),
                    IconButton(
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => notifier.hardDelete(a.id)),
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
