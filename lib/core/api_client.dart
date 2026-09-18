import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<String?> Function()? onRefreshToken,
  VoidCallback? onSessionExpired,
  void Function(String message)? onForbidden,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  Future<String?>? refreshFuture;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API REQ] ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        final status = response.statusCode ?? 200;
        final path = response.requestOptions.path;

        if (kDebugMode) {
          debugPrint(
              '[API RES] ${response.requestOptions.method} ${response.requestOptions.uri} -> $status');
        }

        if (status == 401) {
          final isAuthRoute = path.contains('/auth/login') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/register');

          if (!isAuthRoute && onRefreshToken != null) {
            try {
              refreshFuture ??= onRefreshToken();
              final newToken = await refreshFuture;
              refreshFuture = null;

              if (newToken != null && newToken.isNotEmpty) {
                final retryOptions = response.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newToken';
                final retryRes = await dio.fetch(retryOptions);
                return handler.resolve(retryRes);
              }
            } catch (_) {
              refreshFuture = null;
            }

            onSessionExpired?.call();
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: const UnauthorizedException(
                    'Сессия истекла. Войдите снова.'),
              ),
              true,
            );
          }
        }

        if (status == 403) {
          const msg = 'У вас недостаточно прав для выполнения этой операции.';
          onForbidden?.call(msg);
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: const ForbiddenException(msg),
            ),
            true,
          );
        }

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }

        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
              '[API ERR] ${error.requestOptions.uri}: ${error.type} | ${error.message}');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}
