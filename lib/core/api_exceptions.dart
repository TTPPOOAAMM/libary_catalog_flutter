import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение или настройки CORS в консоли браузера.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется авторизация в системе.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Недостаточно прав для выполнения операции.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запрашиваемая запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Внутренняя ошибка сервера (5xx). Попробуйте позже.']);
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String) ? body['message'] as String : null;

  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется авторизация.'),
    403 => ForbiddenException(message ?? 'Доступ запрещён.'),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Конфликт данных при выполнении операции.'),
    422 => ValidationException(
        message ?? 'Ошибка валидации данных',
        (body is Map && body['errors'] is Map)
            ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
            : const {},
      ),
    _ => ServerException(message ?? 'Ошибка сервера (код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Превышено время ожидания ответа сервера.'),
    DioExceptionType.connectionError =>
      const NetworkException(
        'Не удалось соединиться с сервером. '
        'Если сервер запущен, проверьте консоль браузера (F12) на наличие ошибки CORS.',
      ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}