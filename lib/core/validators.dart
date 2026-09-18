typedef Validator = String? Function(String?);

class V {
  static Validator required(
      [String message = 'Поле обязательно для заполнения']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  static Validator integer({int? min, int? max}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      final n = int.tryParse(text);
      if (n == null) return 'Введите целое число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator email() {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      return re.hasMatch(text) ? null : 'Некорректный адрес электронной почты';
    };
  }

  static Validator isbn() {
    final re = RegExp(
        r'^(?:ISBN(?:-13)?:?\s*)?(?=[0-9]{13}$|(?=(?:[0-9]+[-\s]){4})[-\s0-9]{17}$)97[89][-\s]?[0-9]{1,5}[-\s]?[0-9]+[-\s]?[0-9]+[-\s]?[0-9]$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      return re.hasMatch(text) ? null : 'Формат: 978-X-XXXXX-XXX-X';
    };
  }

  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

class PasswordStrength {
  final bool hasMinLength;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordStrength({
    required this.hasMinLength,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  bool get isValid => hasMinLength && hasDigit && hasSpecialChar;

  factory PasswordStrength.evaluate(String password) {
    return PasswordStrength(
      hasMinLength: password.length >= 8,
      hasDigit: RegExp(r'\d').hasMatch(password),
      hasSpecialChar:
          RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(password),
    );
  }
}
