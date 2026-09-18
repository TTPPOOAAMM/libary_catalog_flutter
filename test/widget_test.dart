import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_catalog/core/permissions.dart';
import 'package:library_catalog/models/author.dart';
import 'package:library_catalog/models/author_query.dart';
import 'package:library_catalog/models/book.dart';
import 'package:library_catalog/models/book_query.dart';
import 'package:library_catalog/models/genre.dart';
import 'package:library_catalog/models/genre_query.dart';
import 'package:library_catalog/models/page_result.dart';
import 'package:library_catalog/models/publisher.dart';
import 'package:library_catalog/models/publisher_query.dart';
import 'package:library_catalog/models/user.dart';
import 'package:library_catalog/repositories/author_repository.dart';
import 'package:library_catalog/repositories/book_repository.dart';
import 'package:library_catalog/repositories/genre_repository.dart';
import 'package:library_catalog/repositories/publisher_repository.dart';
import 'package:library_catalog/screens/book_form_screen.dart';
import 'package:library_catalog/screens/book_list_screen.dart';
import 'package:library_catalog/state/auth_notifier.dart';
import 'package:library_catalog/state/book_list_notifier.dart';
import 'package:provider/provider.dart';
import 'package:library_catalog/core/validators.dart';

class FakeBookRepository implements BookRepository {
  final List<Book> items;
  final bool shouldFail;
  final Completer<PageResult<Book>>? delayCompleter;

  FakeBookRepository({
    this.items = const [],
    this.shouldFail = false,
    this.delayCompleter,
  });

  @override
  Future<PageResult<Book>> find(BookQuery query) async {
    if (delayCompleter != null) {
      return delayCompleter!.future;
    }
    if (shouldFail) {
      throw Exception('Сервер временно недоступен');
    }
    return PageResult<Book>(
      items: items,
      page: query.page,
      size: query.size,
      total: items.length,
    );
  }

  @override
  Future<Book?> findById(int id) async =>
      items.where((b) => b.id == id).firstOrNull;

  @override
  Future<Book> create(Book book) async => book;

  @override
  Future<Book> update(Book book) async => book;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;

  @override
  Future<bool> isIsbnUnique(String isbn, {int? excludeId}) async => true;
}

class FakePublisherRepository implements PublisherRepository {
  @override
  Future<List<Publisher>> findAll() async => [
        const Publisher(id: 1, name: 'Тестовое изд.', city: 'Москва'),
      ];

  @override
  Future<int> countBooksReferencing(int publisherId) async => 0;

  @override
  Future<PageResult<Publisher>> find(PublisherQuery query) async =>
      PageResult.empty();

  @override
  Future<Publisher?> findById(int id) async => null;

  @override
  Future<Publisher> create(Publisher p) async => p;

  @override
  Future<Publisher> update(Publisher p) async => p;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

class FakeAuthorRepository implements AuthorRepository {
  @override
  Future<List<Author>> findAll() async => [
        const Author(
          id: 1,
          firstName: 'Лев',
          lastName: 'Толстой',
          country: 'РФ',
          birthYear: 1828,
        ),
      ];

  @override
  Future<PageResult<Author>> find(AuthorQuery query) async =>
      PageResult.empty();

  @override
  Future<Author?> findById(int id) async => null;

  @override
  Future<Author> create(Author a) async => a;

  @override
  Future<Author> update(Author a) async => a;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

class FakeGenreRepository implements GenreRepository {
  @override
  Future<List<Genre>> findAll() async => [
        const Genre(id: 1, name: 'Роман', description: 'Описание романа'),
      ];

  @override
  Future<PageResult<Genre>> find(GenreQuery query) async => PageResult.empty();

  @override
  Future<Genre?> findById(int id) async => null;

  @override
  Future<Genre> create(Genre g) async => g;

  @override
  Future<Genre> update(Genre g) async => g;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

class MockAuthNotifier extends ChangeNotifier implements AuthNotifier {
  final UserRole mockRole;
  MockAuthNotifier({this.mockRole = UserRole.admin});

  @override
  UserRole get currentRole => mockRole;

  @override
  User? get currentUser => User(
        id: 1,
        username: 'test',
        fullName: 'Тестовый Пользователь',
        email: 't@t.ru',
        role: mockRole,
      );

  @override
  bool get isAuthenticated => true;

  @override
  bool get isInitialized => true;

  @override
  String? get accessToken => 'mock_token';

  @override
  bool get isWarningActive => false;

  @override
  int get secondsUntilLogout => 30;

  @override
  String? get sessionExpiredMessage => null;

  @override
  void recordActivity() {}

  @override
  void clearSessionMessage() {}

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String role,
  }) async {}

  @override
  Future<String?> refreshAccessToken() async => 'new_token';

  @override
  Future<void> simulateDevToolsRoleChange(UserRole spoofedRole) async {}

  @override
  Future<void> logout({String? reason}) async {}
}

Widget buildTestApp({
  required Widget child,
  required BookRepository bookRepo,
  UserRole role = UserRole.admin,
}) {
  return MultiProvider(
    providers: [
      Provider<BookRepository>.value(value: bookRepo),
      Provider<PublisherRepository>.value(value: FakePublisherRepository()),
      Provider<AuthorRepository>.value(value: FakeAuthorRepository()),
      Provider<GenreRepository>.value(value: FakeGenreRepository()),
      ChangeNotifierProvider<AuthNotifier>.value(
        value: MockAuthNotifier(mockRole: role),
      ),
      ChangeNotifierProvider<BookListNotifier>(
        create: (_) => BookListNotifier(bookRepo),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('1. Состояние загрузки отображает CircularProgressIndicator',
      (tester) async {
    final completer = Completer<PageResult<Book>>();
    final repo = FakeBookRepository(delayCompleter: completer);

    await tester.pumpWidget(buildTestApp(
      child: const BookListScreen(queryParams: {}),
      bookRepo: repo,
    ));

    // Прокачиваем кадр для запуска addPostFrameCallback
    await tester.pump();

    // Запрос в процессе выполнения: проверяем наличие индикатора
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Завершаем запрос, чтобы не оставлять активных таймеров
    completer.complete(PageResult.empty());
    await tester.pumpAndSettle();
  });

  testWidgets(
      '2. Пустой результат выводит понятное сообщение "Книг не найдено"',
      (tester) async {
    final repo = FakeBookRepository(items: []);
    await tester.pumpWidget(buildTestApp(
      child: const BookListScreen(queryParams: {}),
      bookRepo: repo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Книг не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('3. Состояние ошибки показывает текст сбоя и кнопку повтора',
      (tester) async {
    final repo = FakeBookRepository(shouldFail: true);
    await tester.pumpWidget(buildTestApp(
      child: const BookListScreen(queryParams: {}),
      bookRepo: repo,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Сервер временно недоступен'), findsOneWidget);
    expect(find.text('Повторить попытку'), findsOneWidget);
  });

  testWidgets(
      '4. Валидация формы срабатывает при попытке сохранить пустые обязательные поля',
      (tester) async {
    final repo = FakeBookRepository();
    await tester.pumpWidget(buildTestApp(
      child: const BookFormScreen(),
      bookRepo: repo,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    // Получаем реальную строку ошибки валидатора V.required()
    final requiredError = V.required()('');
    expect(requiredError, isNotNull);
    expect(find.text(requiredError!), findsWidgets);
  });

  testWidgets(
      '5. Скрытие недоступного элемента UI: кнопка добавления книги скрыта для роли Reader',
      (tester) async {
    final repo = FakeBookRepository(items: []);
    await tester.pumpWidget(buildTestApp(
      child: const BookListScreen(queryParams: {}),
      bookRepo: repo,
      role: UserRole.reader,
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsNothing);
  });
}
