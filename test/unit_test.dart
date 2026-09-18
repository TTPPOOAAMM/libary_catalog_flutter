import 'package:flutter_test/flutter_test.dart';
import 'package:library_catalog/core/config.dart';
import 'package:library_catalog/core/permissions.dart';
import 'package:library_catalog/core/validators.dart';
import 'package:library_catalog/models/author.dart';
import 'package:library_catalog/models/book.dart';
import 'package:library_catalog/models/loan.dart';
import 'package:library_catalog/models/user.dart';

void main() {
  group('1. Валидаторы пользовательского ввода', () {
    test(
        '1.1. Обязательное поле: пустая строка отклоняется, заполненная принимается',
        () {
      final v = V.required();
      expect(v(''), isNotNull);
      expect(v('   '), isNotNull);
      expect(v('Война и мир'), isNull);
    });

    test('1.2. Email: проверяется корректность синтаксиса почты', () {
      final v = V.email();
      expect(v('invalid-email'), isNotNull);
      expect(v('test@domain.com'), isNull);
    });

    test('1.3. Надежность пароля: оценка длины, цифр и спецсимволов', () {
      expect(PasswordStrength.evaluate('short').isValid, isFalse);
      expect(PasswordStrength.evaluate('Password123').isValid, isFalse);
      expect(PasswordStrength.evaluate('SecurePass123!').isValid, isTrue);
    });
  });

  group('2. Разбор и устойчивость моделей (Parsing & Fallbacks)', () {
    test(
        '2.1. Book.fromJson: устойчив к неполным объектам и парсит вложенных авторов',
        () {
      final b = Book.fromJson({
        'id': 1,
        'title': 'Чистый код',
        'authors': [
          {'id': 10, 'name': 'Мартин Р.'}
        ]
      });
      expect(b.title, 'Чистый код');
      expect(b.authorIds, [10]);
      expect(b.year, 0);
    });

    test(
        '2.2. Author.fromJson: объединяет имя и фамилию при наличии единого fullName',
        () {
      final a = Author.fromJson({'id': 5, 'fullName': 'Лев Толстой'});
      expect(a.firstName, 'Лев');
      expect(a.lastName, 'Толстой');
      expect(a.fullName, 'Лев Толстой');
    });

    test('2.3. User.fromJson: корректно восстанавливает роль из строки', () {
      final u = User.fromJson({
        'id': 2,
        'username': 'lib_user',
        'fullName': 'Иванов И.',
        'email': 'i@test.ru',
        'role': 'librarian',
      });
      expect(u.role, UserRole.librarian);
    });

    test('2.4. Loan: вычисляет статус просрочки книги', () {
      final overdueLoan = Loan(
        id: 1,
        bookId: 10,
        bookTitle: 'Книга',
        readerId: 2,
        readerName: 'Петров',
        issuedAt: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(overdueLoan.isOverdue, isTrue);
    });
  });

  group('3. Ролевой доступ и параметры сессии', () {
    test('3.1. RBAC: Читатель не имеет доступа к созданию книг и пользователям',
        () {
      expect(AppPermissions.canManageBooks(UserRole.reader), isFalse);
      expect(AppPermissions.canManageUsers(UserRole.reader), isFalse);
    });

    test(
        '3.2. SessionConfig: интервал неактивности равен 3 минутам, предупреждение - 30 сек',
        () {
      expect(SessionConfig.inactivityTimeout, const Duration(minutes: 3));
      expect(
          SessionConfig.inactivityWarningDuration, const Duration(seconds: 30));
    });
  });
}
