import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  final List<Author> _authors = [
      const Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828),
      const Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821),
      const Author(id: 3, firstName: 'Александр', lastName: 'Пушкин', country: 'Россия', birthYear: 1799),
      const Author(id: 11, firstName: 'Николай', lastName: 'Гоголь', country: 'Россия', birthYear: 1809),
      const Author(id: 12, firstName: 'Михаил', lastName: 'Лермонтов', country: 'Россия', birthYear: 1814),
      const Author(id: 13, firstName: 'Иван', lastName: 'Тургенев', country: 'Россия', birthYear: 1818),
      const Author(id: 14, firstName: 'Антон', lastName: 'Чехов', country: 'Россия', birthYear: 1860),
      const Author(id: 15, firstName: 'Иван', lastName: 'Гончаров', country: 'Россия', birthYear: 1812),
      const Author(id: 16, firstName: 'Александр', lastName: 'Грибоедов', country: 'Россия', birthYear: 1795),
      const Author(id: 17, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия', birthYear: 1891),
      const Author(id: 18, firstName: 'Михаил', lastName: 'Шолохов', country: 'Россия', birthYear: 1905),
      const Author(id: 19, firstName: 'Борис', lastName: 'Пастернак', country: 'Россия', birthYear: 1890),
  ];

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(needle) ||
              a.country.toLowerCase().contains(needle))
          .toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.compareTo(b.country),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _authors.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i != -1) _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i != -1) _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}