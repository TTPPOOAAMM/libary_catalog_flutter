import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'author_repository.dart';
import 'genre_repository.dart';
import 'publisher_repository.dart';
import 'reader_repository.dart';

List<Map<String, dynamic>> _extractItems(dynamic rawData) {
  List list = const [];
  if (rawData is List) {
    list = rawData;
  } else if (rawData is Map) {
    if (rawData['items'] is List) {
      list = rawData['items'] as List;
    } else if (rawData['data'] is List) {
      list = rawData['data'] as List;
    }
  }
  return list
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
}

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;
  ApiAuthorRepository(this._dio);

  @override
  Future<List<Author>> findAll() => guard(() async {
        final res = await _dio.get('/authors', queryParameters: {'size': 100});
        final list = _extractItems(res.data);
        return list.map(Author.fromJson).toList();
      });

  @override
  Future<PageResult<Author>> find(AuthorQuery q) => guard(() async {
        final res =
            await _dio.get('/authors', queryParameters: q.toQueryParams());
        final list = _extractItems(res.data);
        final items = list.map(Author.fromJson).toList();
        final rawData = res.data;
        int page = q.page;
        int size = q.size;
        int total = items.length;
        if (rawData is Map) {
          page = rawData['page'] as int? ?? page;
          size = rawData['size'] as int? ?? size;
          total = rawData['total'] as int? ?? total;
        }
        return PageResult(items: items, page: page, size: size, total: total);
      });

  @override
  Future<Author?> findById(int id) => guard(() async {
        final res = await _dio.get('/authors/$id');
        final raw = res.data;
        return raw is Map
            ? Author.fromJson(Map<String, dynamic>.from(raw))
            : null;
      });

  @override
  Future<Author> create(Author a) => guard(() async {
        final res = await _dio.post('/authors', data: a.toJson());
        return Author.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<Author> update(Author a) => guard(() async {
        final res = await _dio.put('/authors/${a.id}', data: a.toJson());
        return Author.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/authors/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/authors/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/authors/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final res = await _dio.post('/authors/bulk-delete', data: {'ids': ids});
        final data = res.data;
        return (data is Map && data['deleted'] is int)
            ? data['deleted'] as int
            : ids.length;
      });
}

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;
  ApiGenreRepository(this._dio);

  @override
  Future<List<Genre>> findAll() => guard(() async {
        final res = await _dio.get('/genres', queryParameters: {'size': 100});
        final list = _extractItems(res.data);
        return list.map(Genre.fromJson).toList();
      });

  @override
  Future<PageResult<Genre>> find(GenreQuery q) => guard(() async {
        final res =
            await _dio.get('/genres', queryParameters: q.toQueryParams());
        final list = _extractItems(res.data);
        final items = list.map(Genre.fromJson).toList();
        final rawData = res.data;
        int page = q.page;
        int size = q.size;
        int total = items.length;
        if (rawData is Map) {
          page = rawData['page'] as int? ?? page;
          size = rawData['size'] as int? ?? size;
          total = rawData['total'] as int? ?? total;
        }
        return PageResult(items: items, page: page, size: size, total: total);
      });

  @override
  Future<Genre?> findById(int id) => guard(() async {
        final res = await _dio.get('/genres/$id');
        final raw = res.data;
        return raw is Map
            ? Genre.fromJson(Map<String, dynamic>.from(raw))
            : null;
      });

  @override
  Future<Genre> create(Genre g) => guard(() async {
        final res = await _dio.post('/genres', data: g.toJson());
        return Genre.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<Genre> update(Genre g) => guard(() async {
        final res = await _dio.put('/genres/${g.id}', data: g.toJson());
        return Genre.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/genres/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/genres/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/genres/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final res = await _dio.post('/genres/bulk-delete', data: {'ids': ids});
        final data = res.data;
        return (data is Map && data['deleted'] is int)
            ? data['deleted'] as int
            : ids.length;
      });
}

class ApiPublisherRepository implements PublisherRepository {
  final Dio _dio;
  ApiPublisherRepository(this._dio);

  @override
  Future<List<Publisher>> findAll() => guard(() async {
        final res =
            await _dio.get('/publishers', queryParameters: {'size': 100});
        final list = _extractItems(res.data);
        return list.map(Publisher.fromJson).toList();
      });

  @override
  Future<int> countBooksReferencing(int publisherId) => guard(() async {
        final res = await _dio.get('/books',
            queryParameters: {'publisherId': publisherId, 'size': 1});
        final data = res.data;
        return (data is Map && data['total'] is int) ? data['total'] as int : 0;
      });

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) => guard(() async {
        final res =
            await _dio.get('/publishers', queryParameters: q.toQueryParams());
        final list = _extractItems(res.data);
        final items = list.map(Publisher.fromJson).toList();
        final rawData = res.data;
        int page = q.page;
        int size = q.size;
        int total = items.length;
        if (rawData is Map) {
          page = rawData['page'] as int? ?? page;
          size = rawData['size'] as int? ?? size;
          total = rawData['total'] as int? ?? total;
        }
        return PageResult(items: items, page: page, size: size, total: total);
      });

  @override
  Future<Publisher?> findById(int id) => guard(() async {
        final res = await _dio.get('/publishers/$id');
        final raw = res.data;
        return raw is Map
            ? Publisher.fromJson(Map<String, dynamic>.from(raw))
            : null;
      });

  @override
  Future<Publisher> create(Publisher p) => guard(() async {
        final res = await _dio.post('/publishers', data: p.toJson());
        return Publisher.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<Publisher> update(Publisher p) => guard(() async {
        final res = await _dio.put('/publishers/${p.id}', data: p.toJson());
        return Publisher.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/publishers/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
      () => _dio.delete('/publishers/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/publishers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final res =
            await _dio.post('/publishers/bulk-delete', data: {'ids': ids});
        final data = res.data;
        return (data is Map && data['deleted'] is int)
            ? data['deleted'] as int
            : ids.length;
      });
}

class ApiReaderRepository implements ReaderRepository {
  final Dio _dio;
  ApiReaderRepository(this._dio);

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) async {
    try {
      final res = await find(ReaderQuery(search: email.trim(), size: 5));
      return !res.items.any((r) =>
          r.id != excludeId &&
          r.email.toLowerCase() == email.trim().toLowerCase());
    } catch (_) {
      return true;
    }
  }

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) => guard(() async {
        final res =
            await _dio.get('/readers', queryParameters: q.toQueryParams());
        final list = _extractItems(res.data);
        final items = list.map(Reader.fromJson).toList();
        final rawData = res.data;
        int page = q.page;
        int size = q.size;
        int total = items.length;
        if (rawData is Map) {
          page = rawData['page'] as int? ?? page;
          size = rawData['size'] as int? ?? size;
          total = rawData['total'] as int? ?? total;
        }
        return PageResult(items: items, page: page, size: size, total: total);
      });

  @override
  Future<Reader?> findById(int id) => guard(() async {
        final res = await _dio.get('/readers/$id');
        final raw = res.data;
        return raw is Map
            ? Reader.fromJson(Map<String, dynamic>.from(raw))
            : null;
      });

  @override
  Future<Reader> create(Reader r) => guard(() async {
        final res = await _dio.post('/readers', data: r.toJson());
        return Reader.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<Reader> update(Reader r) => guard(() async {
        final res = await _dio.put('/readers/${r.id}', data: r.toJson());
        return Reader.fromJson(Map<String, dynamic>.from(res.data as Map));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/readers/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/readers/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/readers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final res = await _dio.post('/readers/bulk-delete', data: {'ids': ids});
        final data = res.data;
        return (data is Map && data['deleted'] is int)
            ? data['deleted'] as int
            : ids.length;
      });
}
