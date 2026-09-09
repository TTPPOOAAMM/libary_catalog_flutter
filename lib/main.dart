import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/persistent_repositories.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/publisher_list_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/reader_list_screen.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  late final PersistentBookRepository bookRepo;
  final pubRepo = PersistentPublisherRepository(prefs, () => bookRepo);
  bookRepo = PersistentBookRepository(prefs);
  final autRepo = PersistentAuthorRepository(prefs);
  final genRepo = PersistentGenreRepository(prefs);
  final readRepo = PersistentReaderRepository(prefs);

  final router = GoRouter(
    initialLocation: '/books',
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/books',
      ),
      GoRoute(
        path: '/books',
        builder: (c, s) => BookListScreen(queryParams: s.uri.queryParameters),
        routes: [
          GoRoute(path: 'new', builder: (c, s) => const BookFormScreen()),
          GoRoute(path: ':id/edit', builder: (c, s) => BookFormScreen(id: int.tryParse(s.pathParameters['id'] ?? ''))),
          GoRoute(
            path: ':id',
            builder: (c, s) {
              final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
              return BookDetailScreen(bookId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/authors',
        builder: (c, s) => AuthorListScreen(queryParams: s.uri.queryParameters),
        routes: [
          GoRoute(
            path: ':id',
            builder: (c, s) {
              final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
              return AuthorDetailScreen(authorId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/publishers',
        builder: (c, s) => PublisherListScreen(queryParams: s.uri.queryParameters),
      ),
      GoRoute(
        path: '/readers',
        builder: (c, s) => ReaderListScreen(queryParams: s.uri.queryParameters),
        routes: [
          GoRoute(path: 'new', builder: (c, s) => const ReaderFormScreen()),
          GoRoute(path: ':id/edit', builder: (c, s) => ReaderFormScreen(id: int.tryParse(s.pathParameters['id'] ?? ''))),
        ],
      ),
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>.value(value: bookRepo),
        Provider<PublisherRepository>.value(value: pubRepo),
        Provider<AuthorRepository>.value(value: autRepo),
        Provider<GenreRepository>.value(value: genRepo),
        Provider<ReaderRepository>.value(value: readRepo),
        ChangeNotifierProvider(create: (ctx) => BookListNotifier(bookRepo)),
        ChangeNotifierProvider(create: (ctx) => AuthorListNotifier(autRepo)),
        ChangeNotifierProvider(create: (ctx) => PublisherListNotifier(pubRepo)),
        ChangeNotifierProvider(create: (ctx) => GenreListNotifier(genRepo)),
        ChangeNotifierProvider(create: (ctx) => ReaderListNotifier(readRepo)),
      ],
      child: MaterialApp.router(
        title: 'Библиотечная система',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    ),
  );
}