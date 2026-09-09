import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'author_repository.dart';
import 'book_repository.dart';
import 'genre_repository.dart';
import 'publisher_repository.dart';
import 'reader_repository.dart';

class PersistentGenreRepository implements GenreRepository {
  static const _key = 'genres_v1';
  final SharedPreferences _prefs;
  List<Genre> _genres = [];

  PersistentGenreRepository(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _genres = const [
        Genre(id: 1, name: 'Роман', description: 'Художественное повествование'),
        Genre(id: 2, name: 'Фантастика', description: 'Научная и мистическая фантастика'),
        Genre(id: 3, name: 'Детектив', description: 'Расследования и тайны'),
        Genre(id: 4, name: 'Научпоп', description: 'Популярная наука'),
      ];
      _save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _genres = list.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _genres = [];
        _save();
      }
    }
  }

  Future<void> _save() async =>
      _prefs.setString(_key, jsonEncode(_genres.map((g) => g.toJson()).toList()));

  @override
  Future<List<Genre>> findAll() async => _genres.where((g) => !g.isDeleted).toList();

  @override
  Future<PageResult<Genre>> find(GenreQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _genres.where((g) => q.includeDeleted || !g.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final s = q.search.trim().toLowerCase();
      rows = rows.where((g) => g.name.toLowerCase().contains(s)).toList();
    }
    rows.sort((a, b) => q.sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    return PageResult(items: from >= total ? [] : rows.sublist(from, to), page: q.page, size: q.size, total: total);
  }

  @override
  Future<Genre?> findById(int id) async {
    try {
      return _genres.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Genre> create(Genre genre) async {
    final nextId = _genres.isEmpty ? 1 : _genres.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
    final item = Genre(id: nextId, name: genre.name, description: genre.description);
    _genres.add(item);
    await _save();
    return item;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final i = _genres.indexWhere((g) => g.id == genre.id);
    if (i == -1) throw StateError('Не найдено');
    _genres[i] = genre;
    await _save();
    return genre;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i != -1) {
      _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
      await _save();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _genres.removeWhere((g) => g.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i != -1) {
      _genres[i] = _genres[i].copyWith(clearDeletedAt: true);
      await _save();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var c = 0;
    for (final id in ids) {
      final i = _genres.indexWhere((g) => g.id == id && !g.isDeleted);
      if (i != -1) {
        _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
        c++;
      }
    }
    await _save();
    return c;
  }
}

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v1';
  final SharedPreferences _prefs;
  final BookRepository Function() _bookRepoGetter;
  List<Publisher> _publishers = [];

  PersistentPublisherRepository(this._prefs, this._bookRepoGetter) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _publishers = const [
        Publisher(id: 1, name: 'Азбука', city: 'Санкт-Петербург'),
        Publisher(id: 2, name: 'АСТ', city: 'Москва'),
        Publisher(id: 3, name: 'Эксмо', city: 'Москва'),
      ];
      _save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _publishers = list.map((e) => Publisher.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _publishers = [];
        _save();
      }
    }
  }

  Future<void> _save() async =>
      _prefs.setString(_key, jsonEncode(_publishers.map((p) => p.toJson()).toList()));

  @override
  Future<List<Publisher>> findAll() async => _publishers.where((p) => !p.isDeleted).toList();

  @override
  Future<int> countBooksReferencing(int publisherId) async {
    final res = await _bookRepoGetter().find(const BookQuery(size: 1000, includeDeleted: true));
    return res.items.where((b) => b.publisherId == publisherId).length;
  }

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _publishers.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final s = q.search.trim().toLowerCase();
      rows = rows.where((p) => p.name.toLowerCase().contains(s) || p.city.toLowerCase().contains(s)).toList();
    }
    rows.sort((a, b) => q.sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    return PageResult(items: from >= total ? [] : rows.sublist(from, to), page: q.page, size: q.size, total: total);
  }

  @override
  Future<Publisher?> findById(int id) async {
    try {
      return _publishers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Publisher> create(Publisher p) async {
    final nextId = _publishers.isEmpty ? 1 : _publishers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final item = Publisher(id: nextId, name: p.name, city: p.city);
    _publishers.add(item);
    await _save();
    return item;
  }

  @override
  Future<Publisher> update(Publisher p) async {
    final i = _publishers.indexWhere((e) => e.id == p.id);
    if (i == -1) throw StateError('Не найдено');
    _publishers[i] = p;
    await _save();
    return p;
  }

  @override
  Future<void> softDelete(int id) async {
    final count = await countBooksReferencing(id);
    if (count > 0) throw StateError('Нельзя удалить издательство: к нему привязано $count книг');
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i != -1) {
      _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
      await _save();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    final count = await countBooksReferencing(id);
    if (count > 0) throw StateError('Нельзя удалить издательство: к нему привязано $count книг');
    _publishers.removeWhere((p) => p.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i != -1) {
      _publishers[i] = _publishers[i].copyWith(clearDeletedAt: true);
      await _save();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var c = 0;
    for (final id in ids) {
      final linked = await countBooksReferencing(id);
      if (linked == 0) {
        final i = _publishers.indexWhere((p) => p.id == id && !p.isDeleted);
        if (i != -1) {
          _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
          c++;
        }
      }
    }
    await _save();
    return c;
  }
}

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;
  List<Reader> _readers = [];

  PersistentReaderRepository(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _readers = [
        Reader(
          id: 1,
          fullName: 'Иванов Иван Иванович',
          email: 'ivanov@mpt.ru',
          phone: '+7 999 111-22-33',
          card: LibraryCard(cardNumber: 'LC-1001', issuedAt: DateTime(2025, 9, 1), isActive: true),
        ),
        Reader(
          id: 2,
          fullName: 'Петрова Анна Сергеевна',
          email: 'petrova@mpt.ru',
          phone: '+7 999 444-55-66',
          card: LibraryCard(cardNumber: 'LC-1002', issuedAt: DateTime(2026, 1, 15), isActive: true),
        ),
      ];
      _save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _readers = list.map((e) => Reader.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _readers = [];
        _save();
      }
    }
  }

  Future<void> _save() async =>
      _prefs.setString(_key, jsonEncode(_readers.map((r) => r.toJson()).toList()));

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) async {
    final target = email.trim().toLowerCase();
    return !_readers.any((r) => r.id != excludeId && r.email.trim().toLowerCase() == target);
  }

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _readers.where((r) => q.includeDeleted || !r.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final s = q.search.trim().toLowerCase();
      rows = rows.where((r) => r.fullName.toLowerCase().contains(s) || r.email.toLowerCase().contains(s) || r.card.cardNumber.toLowerCase().contains(s)).toList();
    }
    rows.sort((a, b) => q.sortAscending ? a.fullName.compareTo(b.fullName) : b.fullName.compareTo(a.fullName));
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    return PageResult(items: from >= total ? [] : rows.sublist(from, to), page: q.page, size: q.size, total: total);
  }

  @override
  Future<Reader?> findById(int id) async {
    try {
      return _readers.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Reader> create(Reader r) async {
    if (!await isEmailUnique(r.email)) throw StateError('Читатель с таким email уже существует');
    final nextId = _readers.isEmpty ? 1 : _readers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final item = Reader(id: nextId, fullName: r.fullName, email: r.email, phone: r.phone, card: r.card);
    _readers.add(item);
    await _save();
    return item;
  }

  @override
  Future<Reader> update(Reader r) async {
    if (!await isEmailUnique(r.email, excludeId: r.id)) throw StateError('Email уже используется');
    final i = _readers.indexWhere((e) => e.id == r.id);
    if (i == -1) throw StateError('Не найдено');
    _readers[i] = r;
    await _save();
    return r;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i != -1) {
      _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
      await _save();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _readers.removeWhere((r) => r.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i != -1) {
      _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
      await _save();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var c = 0;
    for (final id in ids) {
      final i = _readers.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
        c++;
      }
    }
    await _save();
    return c;
  }
}

class PersistentBookRepository implements BookRepository {
  static const _key = 'books_v1';
  final SharedPreferences _prefs;
  List<Book> _books = [];

  PersistentBookRepository(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _books = [
        const Book(id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 1300, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 12, copiesAvailable: 8),
        const Book(id: 2, title: 'Анна Каренина', isbn: '978-5-17-090335-1', year: 1877, pages: 864, publisherId: 2, authorIds: [1], genreIds: [1], copiesTotal: 10, copiesAvailable: 4),
        const Book(id: 3, title: 'Преступление и наказание', isbn: '978-5-389-04928-4', year: 1866, pages: 592, publisherId: 1, authorIds: [2], genreIds: [1, 3], copiesTotal: 15, copiesAvailable: 7),
        const Book(id: 4, title: 'Идиот', isbn: '978-5-17-087889-5', year: 1869, pages: 640, publisherId: 3, authorIds: [2], genreIds: [1], copiesTotal: 8, copiesAvailable: 2),
        const Book(id: 5, title: 'Братья Карамазовы', isbn: '978-5-389-02283-6', year: 1880, pages: 832, publisherId: 1, authorIds: [2], genreIds: [1, 3], copiesTotal: 9, copiesAvailable: 5),
        const Book(id: 6, title: 'Евгений Онегин', isbn: '978-5-389-01824-2', year: 1833, pages: 224, publisherId: 2, authorIds: [3], genreIds: [1], copiesTotal: 14, copiesAvailable: 11),
      ];
      _save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _books = list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _books = [];
        _save();
      }
    }
  }

  Future<void> _save() async =>
      _prefs.setString(_key, jsonEncode(_books.map((b) => b.toJson()).toList()));

  @override
  Future<bool> isIsbnUnique(String isbn, {int? excludeId}) async {
    final norm = isbn.replaceAll(RegExp(r'[-\s]'), '');
    return !_books.any((b) => b.id != excludeId && b.isbn.replaceAll(RegExp(r'[-\s]'), '') == norm);
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final s = q.search.trim().toLowerCase();
      rows = rows.where((b) => b.title.toLowerCase().contains(s) || b.isbn.toLowerCase().contains(s)).toList();
    }
    if (q.genreId != null) rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    if (q.publisherId != null) rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    if (q.yearFrom != null) rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    if (q.yearTo != null) rows = rows.where((b) => b.year <= q.yearTo!).toList();

    rows.sort((a, b) {
      final res = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? res : -res;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    return PageResult(items: from >= total ? [] : rows.sublist(from, to), page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book> create(Book book) async {
    if (!await isIsbnUnique(book.isbn)) throw StateError('Книга с таким ISBN уже существует');
    final nextId = _books.isEmpty ? 1 : _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    final created = Book(
      id: nextId,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: book.authorIds,
      genreIds: book.genreIds,
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesAvailable,
    );
    _books.add(created);
    await _save();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    if (!await isIsbnUnique(book.isbn, excludeId: book.id)) throw StateError('ISBN уже занят другой книгой');
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга не найдена');
    _books[i] = book;
    await _save();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i != -1) {
      _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
      await _save();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i != -1) {
      _books[i] = _books[i].copyWith(clearDeletedAt: true);
      await _save();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var c = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        c++;
      }
    }
    await _save();
    return c;
  }
}

class PersistentAuthorRepository implements AuthorRepository {
  static const _key = 'authors_v1';
  final SharedPreferences _prefs;
  List<Author> _authors = [];

  PersistentAuthorRepository(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _authors = const [
        Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828),
        Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821),
        Author(id: 3, firstName: 'Александр', lastName: 'Пушкин', country: 'Россия', birthYear: 1799),
      ];
      _save();
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _authors = list.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _authors = [];
        _save();
      }
    }
  }

  Future<void> _save() async =>
      _prefs.setString(_key, jsonEncode(_authors.map((a) => a.toJson()).toList()));

  @override
  Future<List<Author>> findAll() async => _authors.where((a) => !a.isDeleted).toList();

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final s = q.search.trim().toLowerCase();
      rows = rows.where((a) => a.lastName.toLowerCase().contains(s) || a.country.toLowerCase().contains(s)).toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }
    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.compareTo(b.country),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? r : -r;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    return PageResult(items: from >= total ? [] : rows.sublist(from, to), page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    try {
      return _authors.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Author> create(Author a) async {
    final nextId = _authors.isEmpty ? 1 : _authors.map((e) => e.id).reduce((x, y) => x > y ? x : y) + 1;
    final created = Author(id: nextId, firstName: a.firstName, lastName: a.lastName, country: a.country, birthYear: a.birthYear);
    _authors.add(created);
    await _save();
    return created;
  }

  @override
  Future<Author> update(Author a) async {
    final i = _authors.indexWhere((e) => e.id == a.id);
    if (i == -1) throw StateError('Не найдено');
    _authors[i] = a;
    await _save();
    return a;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i != -1) {
      _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
      await _save();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i != -1) {
      _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
      await _save();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var c = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        c++;
      }
    }
    await _save();
    return c;
  }
}