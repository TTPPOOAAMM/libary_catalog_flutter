import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/debounce_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class GenreListScreen extends StatefulWidget {
  final Map<String, String> queryParams;
  const GenreListScreen({super.key, required this.queryParams});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = GenreQuery.fromQueryParams(widget.queryParams);
      context.read<GenreListNotifier>().setQuerySilently(q);
    });
  }

  void _updateUrl(GenreQuery q) {
    context.go(Uri(path: '/genres', queryParameters: q.toQueryParams()).toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenreListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить жанр',
            onPressed: () => context.go('/genres/new'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: notifier.load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DebounceSearchField(
              initialValue: notifier.query.search,
              hintText: 'Поиск по жанрам...',
              onChanged: (v) => _updateUrl(notifier.query.copyWith(search: v)),
            ),
          ),
          Expanded(
            child: EntityTable<Genre>(
              items: notifier.result.items,
              idOf: (g) => g.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              onSelectAll: (val) => notifier.selectAll(val ?? false),
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              onSort: (f) => _updateUrl(notifier.query.copyWith(sortField: f)),
              columns: [
                TableColumnSpec(label: 'Название', sortField: 'name', build: (g) => Text(g.name)),
                TableColumnSpec(label: 'Описание', build: (g) => Text(g.description)),
              ],
              actions: (g) => [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => notifier.softDelete(g.id),
                ),
              ],
            ),
          ),
          PaginationBar(
            page: notifier.result.page,
            size: notifier.result.size,
            total: notifier.result.total,
            totalPages: notifier.result.totalPages,
            onPageChanged: (p) => _updateUrl(notifier.query.copyWith(page: p)),
            onSizeChanged: (s) => _updateUrl(notifier.query.copyWith(size: s, page: 1)),
          ),
        ],
      ),
    );
  }
}