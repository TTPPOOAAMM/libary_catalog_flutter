import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../state/auth_notifier.dart';
import '../state/book_list_notifier.dart';
import '../widgets/debounce_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class BookListScreen extends StatefulWidget {
  final Map<String, String> queryParams;
  const BookListScreen({super.key, required this.queryParams});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<Genre> _genres = [];
  List<Publisher> _publishers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = BookQuery.fromQueryParams(widget.queryParams);
      context.read<BookListNotifier>().setQuerySilently(q);
      _loadFilters();
    });
  }

  Future<void> _loadFilters() async {
    try {
      final genreRepo = context.read<GenreRepository>();
      final pubRepo = context.read<PublisherRepository>();
      final g = await genreRepo.findAll();
      final p = await pubRepo.findAll();
      if (mounted) {
        setState(() {
          _genres = g;
          _publishers = p;
        });
      }
    } catch (_) {}
  }

  void _updateUrl(BookQuery q) {
    context
        .go(Uri(path: '/books', queryParameters: q.toQueryParams()).toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final query = notifier.query;
    final auth = context.watch<AuthNotifier>();
    final currentUser = auth.currentUser;
    final currentRole = auth.currentRole;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Каталог книг'),
            if (currentUser != null)
              Text(
                '${currentUser.fullName} (${currentRole.label})',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (AppPermissions.canManageBooks(currentRole))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Добавить книгу',
              onPressed: () => context.go('/books/new'),
            ),
          if (notifier.hasSelection &&
              AppPermissions.canManageBooks(currentRole))
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Удалить выбранные',
              onPressed: () => notifier.deleteSelected(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить список',
            onPressed: () => notifier.load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 200, maxWidth: 360),
                  child: DebounceSearchField(
                    initialValue: query.search,
                    hintText: 'Поиск по названию или ISBN...',
                    onChanged: (v) =>
                        _updateUrl(query.copyWith(search: v, page: 1)),
                  ),
                ),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 160, maxWidth: 220),
                  child: DropdownButtonFormField<int?>(
                    initialValue: query.genreId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Жанр',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Все жанры')),
                      ..._genres.map((g) => DropdownMenuItem(
                          value: g.id,
                          child:
                              Text(g.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (id) =>
                        _updateUrl(query.copyWith(genreId: id, page: 1)),
                  ),
                ),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 160, maxWidth: 220),
                  child: DropdownButtonFormField<int?>(
                    initialValue: query.publisherId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Издательство',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Все издатели')),
                      ..._publishers.map((p) => DropdownMenuItem(
                          value: p.id,
                          child:
                              Text(p.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (id) =>
                        _updateUrl(query.copyWith(publisherId: id, page: 1)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(notifier, currentRole)),
          PaginationBar(
            page: notifier.result.page,
            size: notifier.result.size,
            total: notifier.result.total,
            totalPages: notifier.result.totalPages,
            onPageChanged: (p) => _updateUrl(query.copyWith(page: p)),
            onSizeChanged: (s) => _updateUrl(query.copyWith(size: s, page: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BookListNotifier notifier, UserRole role) {
    if (notifier.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.status == LoadStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                notifier.error ?? 'Ошибка при получении данных каталога',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => notifier.load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить попытку'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifier.result.items.isEmpty) {
      return const Center(
        child: Text('Книг не найдено',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return EntityTable<Book>(
      items: notifier.result.items,
      idOf: (b) => b.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      onSelectAll: (val) => notifier.selectAll(val ?? false),
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: (f) {
        final asc = notifier.query.sortField == f
            ? !notifier.query.sortAscending
            : true;
        _updateUrl(notifier.query.copyWith(sortField: f, sortAscending: asc));
      },
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'title',
          build: (b) => Text(b.title, overflow: TextOverflow.ellipsis),
        ),
        TableColumnSpec(label: 'ISBN', build: (b) => Text(b.isbn)),
        TableColumnSpec(
          label: 'Год',
          sortField: 'year',
          build: (b) => Text(b.year.toString()),
        ),
        TableColumnSpec(
            label: 'Экземпляров',
            build: (b) => Text('${b.copiesAvailable} / ${b.copiesTotal}')),
      ],
      actions: (b) => [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 20),
          tooltip: 'Открыть детали книги',
          onPressed: () => context.go('/books/${b.id}'),
        ),
        if (AppPermissions.canManageBooks(role))
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Редактировать книгу',
            onPressed: () => context.go('/books/${b.id}/edit'),
          ),
      ],
    );
  }
}
