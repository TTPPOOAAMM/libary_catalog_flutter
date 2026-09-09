import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/book_query.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromParams();
    });
  }

  @override
  void didUpdateWidget(covariant BookListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryParams != widget.queryParams) {
      _syncFromParams();
    }
  }

  void _syncFromParams() {
    final query = BookQuery.fromQueryParams(widget.queryParams);
    context.read<BookListNotifier>().setQuerySilently(query);
  }

  void _updateUrl(BookQuery nextQuery) {
    context.go(Uri(path: '/books', queryParameters: nextQuery.toQueryParams()).toString());
  }

  void _confirmDeleteSelected(BuildContext context, BookListNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить выбранные записи (${notifier.selected.length})?'),
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
    final notifier = context.watch<BookListNotifier>();
    final query = notifier.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить книгу',
            onPressed: () => context.go('/books/new'),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Авторы',
            onPressed: () => context.go('/authors'),
          ),
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Издательства',
            onPressed: () => context.go('/publishers'),
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Читатели',
            onPressed: () => context.go('/readers'),
          ),
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
              constraints: const BoxConstraints(maxWidth: 1200),
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
                        hintText: 'Поиск по названию, ISBN...',
                        onChanged: (val) => _updateUrl(query.copyWith(search: val)),
                      ),
                    ),
                    DropdownButton<int?>(
                      value: query.genreId,
                      hint: const Text('Все жанры'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все жанры')),
                        DropdownMenuItem(value: 1, child: Text('Роман')),
                        DropdownMenuItem(value: 2, child: Text('Фантастика')),
                        DropdownMenuItem(value: 3, child: Text('Детектив')),
                        DropdownMenuItem(value: 4, child: Text('Научпоп')),
                      ],
                      onChanged: (val) => _updateUrl(query.copyWith(genreId: val)),
                    ),
                    DropdownButton<int?>(
                      value: query.publisherId,
                      hint: const Text('Все изд-ва'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все изд-ва')),
                        DropdownMenuItem(value: 1, child: Text('Азбука')),
                        DropdownMenuItem(value: 2, child: Text('АСТ')),
                        DropdownMenuItem(value: 3, child: Text('Эксмо')),
                      ],
                      onChanged: (val) => _updateUrl(query.copyWith(publisherId: val)),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Год от', isDense: true),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: query.yearFrom?.toString() ?? ''),
                        onSubmitted: (v) => _updateUrl(query.copyWith(yearFrom: int.tryParse(v))),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Год до', isDense: true),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: query.yearTo?.toString() ?? ''),
                        onSubmitted: (v) => _updateUrl(query.copyWith(yearTo: int.tryParse(v))),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: query.includeDeleted,
                      onSelected: (val) => _updateUrl(query.copyWith(includeDeleted: val)),
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
                    label: const Text('Логическое удаление'),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody(notifier)),
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

  Widget _buildBody(BookListNotifier notifier) {
    return switch (notifier.status) {
      LoadStatus.loading => const Center(child: CircularProgressIndicator()),
      LoadStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(notifier.error ?? 'Ошибка загрузки'),
              FilledButton(onPressed: notifier.load, child: const Text('Повторить')),
            ],
          ),
        ),
      LoadStatus.idle || LoadStatus.success when notifier.result.items.isEmpty => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('По запросу ничего не найдено'),
            ],
          ),
        ),
      _ => EntityTable<Book>(
          items: notifier.result.items,
          idOf: (b) => b.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          onSelectAll: (val) => notifier.selectAll(val ?? false),
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          onSort: (field) {
            final asc = field == notifier.query.sortField ? !notifier.query.sortAscending : true;
            _updateUrl(notifier.query.copyWith(sortField: field, sortAscending: asc));
          },
          onTap: (b) => context.go('/books/${b.id}'),
          columns: [
            TableColumnSpec(
              label: 'Название',
              sortField: 'title',
              build: (b) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(b.title, style: TextStyle(decoration: b.isDeleted ? TextDecoration.lineThrough : null)),
                  Text('ISBN: ${b.isbn}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            TableColumnSpec(
              label: 'Год',
              sortField: 'year',
              numeric: true,
              build: (b) => Text('${b.year}'),
            ),
            TableColumnSpec(
              label: 'Страниц',
              sortField: 'pages',
              numeric: true,
              build: (b) => Text('${b.pages}'),
            ),
            TableColumnSpec(
              label: 'Статус',
              build: (b) => b.isDeleted
                  ? const Chip(label: Text('Удалена', style: TextStyle(color: Colors.red)), visualDensity: VisualDensity.compact)
                  : const Chip(label: Text('Активна'), visualDensity: VisualDensity.compact),
            ),
          ],
          actions: (b) => [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: () => context.go('/books/${b.id}/edit'),
            ),
            if (b.isDeleted)
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                tooltip: 'Восстановить',
                onPressed: () => notifier.restore(b.id),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Логическое удаление',
                onPressed: () => notifier.softDelete(b.id),
              ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Физическое удаление',
              onPressed: () => notifier.hardDelete(b.id),
            ),
          ],
        ),
    };
  }
}