import 'package:flutter_test/flutter_test.dart';
import 'package:library_catalog/core/config.dart';
import 'package:library_catalog/core/permissions.dart';
import 'package:library_catalog/core/validators.dart';

void main() {
  group('1. Тестирование ролевого доступа (RBAC)', () {
    test('1. Читатель (Reader) НЕ может создавать и редактировать книги', () {
      const role = UserRole.reader;
      expect(AppPermissions.canManageBooks(role), isFalse);
      expect(AppPermissions.canManageCatalogs(role), isFalse);
    });

    test('2. Библиотекарь (Librarian) МОЖЕТ управлять книгами, но НЕ пользователями', () {
      const role = UserRole.librarian;
      expect(AppPermissions.canManageBooks(role), isTrue);
      expect(AppPermissions.canManageCatalogs(role), isTrue);
      expect(AppPermissions.canManageUsers(role), isFalse);
      expect(AppPermissions.canChangeUserRole(role), isFalse);
    });

    test('3. Читатель НЕ может управлять пользователями и просматривать /users', () {
      const role = UserRole.reader;
      expect(AppPermissions.canManageUsers(role), isFalse);
    });

    test('4. Администратор (Admin) имеет полный доступ к управлению ролями и пользователям', () {
      const role = UserRole.admin;
      expect(AppPermissions.canManageUsers(role), isTrue);
      expect(AppPermissions.canChangeUserRole(role), isTrue);
      expect(AppPermissions.canHardDelete(role), isTrue);
      expect(AppPermissions.canRestore(role), isTrue);
    });

    test('5. Библиотекарь НЕ может выполнять физическое удаление и смену ролей', () {
      const role = UserRole.librarian;
      expect(AppPermissions.canHardDelete(role), isFalse);
      expect(AppPermissions.canChangeUserRole(role), isFalse);
    });
  });

  group('2. Валидация требований к паролю (Оценка 4)', () {
    test('6. Пароль проверяется на длину >= 8, наличие цифры и спецсимвола', () {
      expect(PasswordStrength.evaluate('short').isValid, isFalse);
      expect(PasswordStrength.evaluate('password123').isValid, isFalse); 
      expect(PasswordStrength.evaluate('Password!').isValid, isFalse); 
      expect(PasswordStrength.evaluate('Admin123!').isValid, isTrue); 
    });
  });

  group('3. Логика тайм-аутов сессии (Оценка 5)', () {
    test('7. Расчёт истечения неактивности (3 мин) и абсолютной длительности (30 мин)', () {
      final now = DateTime.now();

      final activeRecent = now.subtract(const Duration(minutes: 2));
      final isInactiveExpired = now.difference(activeRecent) > SessionConfig.inactivityTimeout;
      expect(isInactiveExpired, isFalse);

      final idleTooLong = now.subtract(const Duration(minutes: 4));
      final isIdleExpired = now.difference(idleTooLong) > SessionConfig.inactivityTimeout;
      expect(isIdleExpired, isTrue);

      final sessionTooLong = now.subtract(const Duration(minutes: 31));
      final isSessionExpired = now.difference(sessionTooLong) > SessionConfig.absoluteSessionTimeout;
      expect(isSessionExpired, isTrue);
    });
  });
}