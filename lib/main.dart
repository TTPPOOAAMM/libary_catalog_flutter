import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/permissions.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_repositories.dart';
import 'repositories/auth_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/cached_repositories.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genre_list_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_loans_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publisher_list_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/reader_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/users_screen.dart';
import 'state/auth_notifier.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'widgets/adaptive_shell.dart';
import 'widgets/session_activity_tracker.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  late final AuthNotifier authNotifier;

  final dio = buildDio(
    tokenProvider: () => authNotifier.accessToken,
    onRefreshToken: () => authNotifier.refreshAccessToken(),
    onSessionExpired: () =>
        authNotifier.logout(reason: 'Сессия истекла. Войдите снова.'),
    onForbidden: (msg) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
      );
    },
  );

  final authRepo = ApiAuthRepository(dio);
  authNotifier = AuthNotifier(authRepo, prefs);

  final bookRepo = ApiBookRepository(dio);
  final userRepo = ApiUserRepository(dio);
  final loanRepo = ApiLoanRepository(dio);

  final cachedPubRepo = CachedPublisherRepository(ApiPublisherRepository(dio));
  final cachedAutRepo = CachedAuthorRepository(ApiAuthorRepository(dio));
  final cachedGenRepo = CachedGenreRepository(ApiGenreRepository(dio));
  final readRepo = ApiReaderRepository(dio);

  final router = GoRouter(
    initialLocation: '/books',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      if (!authNotifier.isInitialized) {
        return null;
      }

      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';
      final isAuth = authNotifier.isAuthenticated;
      final role = authNotifier.currentRole;

      if (!isAuth) {
        if (isAuthRoute) {
          return null;
        }
        final target = state.uri.toString();
        return '/login?from=${Uri.encodeComponent(target)}';
      }

      if (isAuthRoute) {
        return '/books';
      }

      if (path == '/users' && !AppPermissions.canManageUsers(role)) {
        return '/forbidden';
      }
      if (path == '/loans' && !AppPermissions.canManageLoans(role)) {
        return '/forbidden';
      }
      if (path.startsWith('/readers') &&
          !AppPermissions.canManageReaders(role)) {
        return '/forbidden';
      }
      if ((path.startsWith('/genres') || path.startsWith('/publishers')) &&
          !AppPermissions.canManageCatalogs(role)) {
        return '/forbidden';
      }
      if ((path == '/books/new' || path.endsWith('/edit')) &&
          !AppPermissions.canManageBooks(role)) {
        return '/forbidden';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/books'),
      GoRoute(
          path: '/login',
          builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from'])),
      GoRoute(
          path: '/register',
          builder: (c, s) =>
              RegisterScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(path: '/users', builder: (c, s) => const UsersScreen()),
          GoRoute(path: '/loans', builder: (c, s) => const LoansScreen()),
          GoRoute(path: '/my-loans', builder: (c, s) => const MyLoansScreen()),
          GoRoute(
            path: '/books',
            builder: (c, s) =>
                BookListScreen(queryParams: s.uri.queryParameters),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const BookFormScreen()),
              GoRoute(
                  path: ':id/edit',
                  builder: (c, s) => BookFormScreen(
                      id: int.tryParse(s.pathParameters['id'] ?? ''))),
              GoRoute(
                path: ':id',
                builder: (c, s) => BookDetailScreen(
                    bookId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
              ),
            ],
          ),
          GoRoute(
            path: '/authors',
            builder: (c, s) =>
                AuthorListScreen(queryParams: s.uri.queryParameters),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const AuthorFormScreen()),
              GoRoute(
                  path: ':id/edit',
                  builder: (c, s) => AuthorFormScreen(
                      id: int.tryParse(s.pathParameters['id'] ?? ''))),
              GoRoute(
                path: ':id',
                builder: (c, s) => AuthorDetailScreen(
                    authorId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
              ),
            ],
          ),
          GoRoute(
            path: '/genres',
            builder: (c, s) =>
                GenreListScreen(queryParams: s.uri.queryParameters),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const GenreFormScreen()),
            ],
          ),
          GoRoute(
            path: '/publishers',
            builder: (c, s) =>
                PublisherListScreen(queryParams: s.uri.queryParameters),
            routes: [
              GoRoute(
                  path: 'new', builder: (c, s) => const PublisherFormScreen()),
            ],
          ),
          GoRoute(
            path: '/readers',
            builder: (c, s) =>
                ReaderListScreen(queryParams: s.uri.queryParameters),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const ReaderFormScreen()),
              GoRoute(
                  path: ':id/edit',
                  builder: (c, s) => ReaderFormScreen(
                      id: int.tryParse(s.pathParameters['id'] ?? ''))),
            ],
          ),
        ],
      ),
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<Dio>.value(value: dio),
        Provider<BookRepository>.value(value: bookRepo),
        Provider<UserRepository>.value(value: userRepo),
        Provider<LoanRepository>.value(value: loanRepo),
        Provider<PublisherRepository>.value(value: cachedPubRepo),
        Provider<AuthorRepository>.value(value: cachedAutRepo),
        Provider<GenreRepository>.value(value: cachedGenRepo),
        Provider<ReaderRepository>.value(value: readRepo),
        ChangeNotifierProvider(create: (ctx) => BookListNotifier(bookRepo)),
        ChangeNotifierProvider(
            create: (ctx) => AuthorListNotifier(cachedAutRepo)),
        ChangeNotifierProvider(
            create: (ctx) => PublisherListNotifier(cachedPubRepo)),
        ChangeNotifierProvider(
            create: (ctx) => GenreListNotifier(cachedGenRepo)),
        ChangeNotifierProvider(create: (ctx) => ReaderListNotifier(readRepo)),
      ],
      child: MaterialApp.router(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'Библиотечная система',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        routerConfig: router,
        builder: (context, child) {
          return SessionActivityTracker(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    ),
  );
}
