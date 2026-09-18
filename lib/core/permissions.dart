enum UserRole {
  reader('reader', 'Читатель'),
  librarian('librarian', 'Библиотекарь'),
  admin('admin', 'Администратор');

  final String code;
  final String label;
  const UserRole(this.code, this.label);

  static UserRole fromString(String? val) {
    if (val == null) return UserRole.reader;
    final clean = val.toLowerCase().trim();
    return UserRole.values.firstWhere(
      (r) => r.code == clean || r.name == clean,
      orElse: () => UserRole.reader,
    );
  }
}

class AppPermissions {
  static bool canViewCatalog(UserRole? role) => role != null;

  static bool canManageBooks(UserRole? role) =>
      role == UserRole.librarian || role == UserRole.admin;

  static bool canManageCatalogs(UserRole? role) =>
      role == UserRole.librarian || role == UserRole.admin;

  static bool canManageReaders(UserRole? role) =>
      role == UserRole.librarian || role == UserRole.admin;

  static bool canManageLoans(UserRole? role) =>
      role == UserRole.librarian || role == UserRole.admin;

  static bool canViewMyLoans(UserRole? role) =>
      role == UserRole.reader || role == UserRole.admin;

  static bool canExtendLoan(UserRole? role) => role != null;

  static bool canManageUsers(UserRole? role) => role == UserRole.admin;

  static bool canChangeUserRole(UserRole? role) => role == UserRole.admin;

  static bool canHardDelete(UserRole? role) => role == UserRole.admin;

  static bool canRestore(UserRole? role) => role == UserRole.admin;

  static bool canViewStats(UserRole? role) => role == UserRole.admin;
}