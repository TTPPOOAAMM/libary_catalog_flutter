import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class InMemoryBookRepository implements BookRepository {
  final List<Book> _books = [
    const Book(
      id: 1,
      title: 'Война и мир',
      isbn: '978-5-389-06256-6',
      year: 1869,
      pages: 1300,
      publisherId: 1,
      authorIds: [1],
      genreIds: [1],
      copiesTotal: 12,
      copiesAvailable: 8,
    ),
    const Book(
      id: 2,
      title: 'Анна Каренина',
      isbn: '978-5-17-090335-1',
      year: 1877,
      pages: 864,
      publisherId: 2,
      authorIds: [1],
      genreIds: [1],
      copiesTotal: 10,
      copiesAvailable: 4,
    ),
    const Book(
      id: 3,
      title: 'Преступление и наказание',
      isbn: '978-5-389-04928-4',
      year: 1866,
      pages: 592,
      publisherId: 1,
      authorIds: [2],
      genreIds: [1, 3],
      copiesTotal: 15,
      copiesAvailable: 7,
    ),
    const Book(
      id: 4,
      title: 'Идиот',
      isbn: '978-5-17-087889-5',
      year: 1869,
      pages: 640,
      publisherId: 3,
      authorIds: [2],
      genreIds: [1],
      copiesTotal: 8,
      copiesAvailable: 2,
    ),
    const Book(
      id: 5,
      title: 'Братья Карамазовы',
      isbn: '978-5-389-02283-6',
      year: 1880,
      pages: 832,
      publisherId: 1,
      authorIds: [2],
      genreIds: [1, 3],
      copiesTotal: 9,
      copiesAvailable: 5,
    ),
    const Book(
      id: 6,
      title: 'Евгений Онегин',
      isbn: '978-5-389-01824-2',
      year: 1833,
      pages: 224,
      publisherId: 2,
      authorIds: [3],
      genreIds: [1],
      copiesTotal: 14,
      copiesAvailable: 11,
    ),
    const Book(
      id: 7,
      title: 'Капитанская дочка',
      isbn: '978-5-17-087034-9',
      year: 1836,
      pages: 192,
      publisherId: 3,
      authorIds: [3],
      genreIds: [1],
      copiesTotal: 16,
      copiesAvailable: 10,
    ),
    Book(
      id: 8,
      title: 'Пиковая дама',
      isbn: '978-5-389-07445-3',
      year: 1834,
      pages: 96,
      publisherId: 1,
      authorIds: [3],
      genreIds: [1, 3],
      copiesTotal: 7,
      copiesAvailable: 3,
      deletedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    const Book(
      id: 9,
      title: 'Мёртвые души',
      isbn: '978-5-17-083421-1',
      year: 1842,
      pages: 352,
      publisherId: 2,
      authorIds: [11],
      genreIds: [1],
      copiesTotal: 11,
      copiesAvailable: 6,
    ),
    const Book(
      id: 10,
      title: 'Ревизор',
      isbn: '978-5-389-01294-3',
      year: 1836,
      pages: 160,
      publisherId: 3,
      authorIds: [11],
      genreIds: [1],
      copiesTotal: 10,
      copiesAvailable: 8,
    ),
    const Book(
      id: 11,
      title: 'Герой нашего времени',
      isbn: '978-5-17-085642-8',
      year: 1840,
      pages: 224,
      publisherId: 1,
      authorIds: [12],
      genreIds: [1],
      copiesTotal: 13,
      copiesAvailable: 9,
    ),
    const Book(
      id: 12,
      title: 'Отцы и дети',
      isbn: '978-5-389-04533-0',
      year: 1862,
      pages: 288,
      publisherId: 2,
      authorIds: [13],
      genreIds: [1],
      copiesTotal: 8,
      copiesAvailable: 3,
    ),
    const Book(
      id: 13,
      title: 'Дворянское гнездо',
      isbn: '978-5-17-092114-0',
      year: 1859,
      pages: 256,
      publisherId: 3,
      authorIds: [13],
      genreIds: [1],
      copiesTotal: 6,
      copiesAvailable: 4,
    ),
    const Book(
      id: 14,
      title: 'Вишнёвый сад',
      isbn: '978-5-389-02100-6',
      year: 1904,
      pages: 96,
      publisherId: 1,
      authorIds: [14],
      genreIds: [1],
      copiesTotal: 12,
      copiesAvailable: 9,
    ),
    const Book(
      id: 15,
      title: 'Палата № 6',
      isbn: '978-5-17-080922-6',
      year: 1892,
      pages: 128,
      publisherId: 2,
      authorIds: [14],
      genreIds: [1],
      copiesTotal: 5,
      copiesAvailable: 1,
    ),
    const Book(
      id: 16,
      title: 'Обломов',
      isbn: '978-5-389-06899-5',
      year: 1859,
      pages: 496,
      publisherId: 3,
      authorIds: [15],
      genreIds: [1],
      copiesTotal: 9,
      copiesAvailable: 5,
    ),
    const Book(
      id: 17,
      title: 'Горе от ума',
      isbn: '978-5-17-088823-8',
      year: 1825,
      pages: 160,
      publisherId: 1,
      authorIds: [16],
      genreIds: [1],
      copiesTotal: 14,
      copiesAvailable: 12,
    ),
    const Book(
      id: 18,
      title: 'Мастер и Маргарита',
      isbn: '978-5-389-01686-6',
      year: 1967,
      pages: 448,
      publisherId: 2,
      authorIds: [17],
      genreIds: [1, 2],
      copiesTotal: 18,
      copiesAvailable: 6,
    ),
    const Book(
      id: 19,
      title: 'Собачье сердце',
      isbn: '978-5-17-084551-4',
      year: 1925,
      pages: 160,
      publisherId: 3,
      authorIds: [17],
      genreIds: [1, 2],
      copiesTotal: 10,
      copiesAvailable: 7,
    ),
    const Book(
      id: 20,
      title: 'Белая гвардия',
      isbn: '978-5-389-05512-4',
      year: 1925,
      pages: 320,
      publisherId: 1,
      authorIds: [17],
      genreIds: [1],
      copiesTotal: 7,
      copiesAvailable: 4,
    ),
    const Book(
      id: 21,
      title: 'Тихий Дон',
      isbn: '978-5-17-090211-8',
      year: 1928,
      pages: 1500,
      publisherId: 2,
      authorIds: [18],
      genreIds: [1],
      copiesTotal: 11,
      copiesAvailable: 5,
    ),
    const Book(
      id: 22,
      title: 'Доктор Живаго',
      isbn: '978-5-389-07890-1',
      year: 1957,
      pages: 544,
      publisherId: 3,
      authorIds: [19],
      genreIds: [1],
      copiesTotal: 8,
      copiesAvailable: 4,
    ),
  ];

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(needle) ||
              b.isbn.toLowerCase().contains(needle))
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    if (q.yearTo != null) rows = rows.where((b) => b.year <= q.yearTo!).toList();

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book> create(Book book) async {
    final newId = _books.isEmpty ? 1 : _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    final created = book.copyWith();
    final withId = Book(
      id: newId,
      title: created.title,
      isbn: created.isbn,
      year: created.year,
      pages: created.pages,
      publisherId: created.publisherId,
      authorIds: created.authorIds,
      genreIds: created.genreIds,
      copiesTotal: created.copiesTotal,
      copiesAvailable: created.copiesAvailable,
    );
    _books.add(withId);
    return withId;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book;
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}