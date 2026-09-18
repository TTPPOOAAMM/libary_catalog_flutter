import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;
  CancelToken? _searchCancelToken;

  ApiBookRepository(this._dio);

  Future<T> _retryRead<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action();
      } catch (e) {
        if (e is ValidationException ||
            e is NotFoundException ||
            e is ConflictException ||
            e is UnauthorizedException ||
            e is ForbiddenException) {
          rethrow;
        }
        if (e is NetworkException && e.message.contains('отменён')) {
          rethrow;
        }
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(initialDelay * attempt);
      }
    }
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) {
    _searchCancelToken?.cancel('Запрос отменён новым поиском');
    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    return _retryRead(() => guard(() async {
          final response = await _dio.get(
            '/books',
            queryParameters: q.toApiParams(),
            cancelToken: cancelToken,
          );
          final data = response.data as Map<String, dynamic>;
          final rawItems = (data['items'] as List?) ?? const [];
          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .map(Book.fromJson)
              .toList();

          return PageResult<Book>(
            items: items,
            page: data['page'] as int? ?? q.page,
            size: data['size'] as int? ?? q.size,
            total: data['total'] as int? ?? items.length,
          );
        }));
  }

  @override
  Future<Book?> findById(int id) {
    return _retryRead(() => guard(() async {
          final response = await _dio.get('/books/$id');
          if (response.data == null) return null;
          return Book.fromJson(response.data as Map<String, dynamic>);
        }));
  }

  @override
  Future<Book> create(Book book) => guard(() async {
        final response = await _dio.post('/books', data: book.toApiJson());
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Book> update(Book book) => guard(() async {
        final response =
            await _dio.put('/books/${book.id}', data: book.toApiJson());
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete('/books/$id', queryParameters: {'hard': true}),
      );

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/books/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/books/bulk-delete', data: {'ids': ids});
        final data = response.data as Map<String, dynamic>;
        return data['deleted'] as int? ?? ids.length;
      });

  @override
  Future<bool> isIsbnUnique(String isbn, {int? excludeId}) async {
    try {
      final res = await find(BookQuery(search: isbn.trim(), size: 5));
      final clean = isbn.replaceAll(RegExp(r'[-\s]'), '');
      return !res.items.any((b) =>
          b.id != excludeId &&
          b.isbn.replaceAll(RegExp(r'[-\s]'), '') == clean);
    } catch (_) {
      return true;
    }
  }
}
