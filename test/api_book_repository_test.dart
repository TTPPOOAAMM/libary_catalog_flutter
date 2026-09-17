import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_catalog/core/api_client.dart';
import 'package:library_catalog/core/api_exceptions.dart';
import 'package:library_catalog/models/book.dart';
import 'package:library_catalog/models/book_query.dart';
import 'package:library_catalog/repositories/api_book_repository.dart';

class MockAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'Mock connection error',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late MockAdapter mockAdapter;
  late ApiBookRepository repository;

  setUp(() {
    dio = buildDio();
    mockAdapter = MockAdapter();
    dio.httpClientAdapter = mockAdapter;
    repository = ApiBookRepository(dio);
  });

  test('1. Успешный GET /books разбирает элементы и пагинацию', () async {
    mockAdapter.handler = (options) {
      expect(options.path, '/books');
      final jsonResponse = {
        'items': [
          {
            'id': 10,
            'title': 'Евгений Онегин',
            'isbn': '978-5-389-01824-2',
            'year': 1833,
            'pages': 224,
            'publisher': {'id': 2, 'name': 'АСТ'},
            'authors': [{'id': 3, 'fullName': 'Пушкин А. С.'}],
            'genres': [{'id': 1, 'name': 'Роман'}],
            'copiesTotal': 5,
            'copiesAvailable': 3,
          }
        ],
        'page': 1,
        'size': 10,
        'total': 1,
        'totalPages': 1
      };
      return ResponseBody.fromString(
        jsonEncode(jsonResponse),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    };

    final result = await repository.find(const BookQuery());
    expect(result.items.length, 1);
    expect(result.items.first.title, 'Евгений Онегин');
    expect(result.items.first.publisherId, 2);
    expect(result.total, 1);
  });

  test('2. Пагинация передаёт параметры page и size на сервер', () async {
    mockAdapter.handler = (options) {
      expect(options.queryParameters['page'], 3);
      expect(options.queryParameters['size'], 25);
      expect(options.queryParameters['sort'], 'year,desc');
      return ResponseBody.fromString(
        jsonEncode({'items': [], 'page': 3, 'size': 25, 'total': 100}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    };

    final res = await repository.find(
      const BookQuery(page: 3, size: 25, sortField: 'year', sortAscending: false),
    );
    expect(res.page, 3);
    expect(res.size, 25);
  });

  test('3. Ошибка 422 преобразуется в ValidationException с картой полей', () async {
    mockAdapter.handler = (options) {
      final jsonErr = {
        'message': 'Ошибка валидации',
        'errors': {
          'isbn': 'Книга с таким ISBN уже существует',
          'year': 'Год не может быть в будущем'
        }
      };
      return ResponseBody.fromString(
        jsonEncode(jsonErr),
        422,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    };

    expect(
      () => repository.create(const Book(
        id: 0,
        title: 'Дубликат',
        isbn: '978-5-389-06256-6',
        year: 2099,
        pages: 100,
        publisherId: 1,
        authorIds: [1],
        genreIds: [1],
        copiesTotal: 1,
        copiesAvailable: 1,
      )),
      throwsA(isA<ValidationException>().having(
        (e) => e.errors['isbn'],
        'isbn error',
        'Книга с таким ISBN уже существует',
      )),
    );
  });

  test('4. Ошибка сервера (500) преобразуется в ServerException', () async {
    mockAdapter.handler = (options) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Internal Server Error'}),
        500,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    };

    expect(() => repository.findById(1), throwsA(isA<ServerException>()));
  });

  test('5. Недоступность сервера / CORS преобразуется в NetworkException', () async {
    mockAdapter.handler = (options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Failed to connect',
      );
    };

    expect(() => repository.findById(1), throwsA(isA<NetworkException>()));
  });
}