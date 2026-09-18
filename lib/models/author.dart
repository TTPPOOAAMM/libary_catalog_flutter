class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;
    return 'Автор #$id';
  }

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? firstName,
    String? lastName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'country': country,
        'birthYear': birthYear,
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      };

  factory Author.fromJson(Map<String, dynamic> json) {
    String first = (json['firstName'] as String?)?.trim() ?? '';
    String last = (json['lastName'] as String?)?.trim() ?? '';
    final full = (json['fullName'] as String?)?.trim() ??
        (json['name'] as String?)?.trim();

    if (first.isEmpty && last.isEmpty && full != null && full.isNotEmpty) {
      final parts = full.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        first = parts.first;
        last = parts.sublist(1).join(' ');
      } else {
        last = full;
      }
    }

    return Author(
      id: json['id'] as int? ?? 0,
      firstName: first,
      lastName: last,
      country: json['country'] as String? ?? '',
      birthYear: json['birthYear'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}
