import '../models/author.dart';
import '../models/author_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'author_repository.dart';
import 'genre_repository.dart';
import 'publisher_repository.dart';

class CachedAuthorRepository implements AuthorRepository {
  final AuthorRepository _inner;
  List<Author>? _cache;

  CachedAuthorRepository(this._inner);

  @override
  Future<List<Author>> findAll() async {
    if (_cache == null || _cache!.isEmpty) {
      final items = await _inner.findAll();
      if (items.isNotEmpty) _cache = items;
      return items;
    }
    return _cache!;
  }

  void invalidate() => _cache = null;

  @override
  Future<PageResult<Author>> find(AuthorQuery query) => _inner.find(query);
  @override
  Future<Author?> findById(int id) => _inner.findById(id);
  @override
  Future<Author> create(Author author) async {
    invalidate();
    return _inner.create(author);
  }

  @override
  Future<Author> update(Author author) async {
    invalidate();
    return _inner.update(author);
  }

  @override
  Future<void> softDelete(int id) async {
    invalidate();
    return _inner.softDelete(id);
  }

  @override
  Future<void> hardDelete(int id) async {
    invalidate();
    return _inner.hardDelete(id);
  }

  @override
  Future<void> restore(int id) async {
    invalidate();
    return _inner.restore(id);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    invalidate();
    return _inner.deleteMany(ids);
  }
}

class CachedGenreRepository implements GenreRepository {
  final GenreRepository _inner;
  List<Genre>? _cache;

  CachedGenreRepository(this._inner);

  @override
  Future<List<Genre>> findAll() async {
    _cache ??= await _inner.findAll();
    return _cache!;
  }

  void invalidate() => _cache = null;

  @override
  Future<PageResult<Genre>> find(GenreQuery query) => _inner.find(query);
  @override
  Future<Genre?> findById(int id) => _inner.findById(id);
  @override
  Future<Genre> create(Genre genre) async {
    invalidate();
    return _inner.create(genre);
  }

  @override
  Future<Genre> update(Genre genre) async {
    invalidate();
    return _inner.update(genre);
  }

  @override
  Future<void> softDelete(int id) async {
    invalidate();
    return _inner.softDelete(id);
  }

  @override
  Future<void> hardDelete(int id) async {
    invalidate();
    return _inner.hardDelete(id);
  }

  @override
  Future<void> restore(int id) async {
    invalidate();
    return _inner.restore(id);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    invalidate();
    return _inner.deleteMany(ids);
  }
}

class CachedPublisherRepository implements PublisherRepository {
  final PublisherRepository _inner;
  List<Publisher>? _cache;

  CachedPublisherRepository(this._inner);

  @override
  Future<List<Publisher>> findAll() async {
    _cache ??= await _inner.findAll();
    return _cache!;
  }

  void invalidate() => _cache = null;

  @override
  Future<int> countBooksReferencing(int publisherId) =>
      _inner.countBooksReferencing(publisherId);
  @override
  Future<PageResult<Publisher>> find(PublisherQuery query) =>
      _inner.find(query);
  @override
  Future<Publisher?> findById(int id) => _inner.findById(id);
  @override
  Future<Publisher> create(Publisher publisher) async {
    invalidate();
    return _inner.create(publisher);
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    invalidate();
    return _inner.update(publisher);
  }

  @override
  Future<void> softDelete(int id) async {
    invalidate();
    return _inner.softDelete(id);
  }

  @override
  Future<void> hardDelete(int id) async {
    invalidate();
    return _inner.hardDelete(id);
  }

  @override
  Future<void> restore(int id) async {
    invalidate();
    return _inner.restore(id);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    invalidate();
    return _inner.deleteMany(ids);
  }
}
