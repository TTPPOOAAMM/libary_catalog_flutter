import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'state/book_list_notifier.dart';
import 'state/author_list_notifier.dart';
import 'screens/book_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/author_detail_screen.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/books',
  routes: [
    GoRoute(
      path: '/books',
      builder: (context, state) => BookListScreen(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '/books/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return BookDetailScreen(bookId: id);
      },
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => AuthorListScreen(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '/authors/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AuthorDetailScreen(authorId: id);
      },
    ),
  ],
);

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => InMemoryBookRepository()),
        Provider<AuthorRepository>(create: (_) => InMemoryAuthorRepository()),
        ChangeNotifierProvider(
          create: (ctx) => BookListNotifier(ctx.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AuthorListNotifier(ctx.read<AuthorRepository>()),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотечный каталог',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}