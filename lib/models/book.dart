class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isbn': isbn,
        'year': year,
        'pages': pages,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'genreIds': genreIds,
        'copiesTotal': copiesTotal,
        'copiesAvailable': copiesAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'title': title,
        'isbn': isbn,
        'year': year,
        'pages': pages,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'genreIds': genreIds,
        'copiesTotal': copiesTotal,
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    int pubId = 0;
    if (json['publisherId'] is int) {
      pubId = json['publisherId'] as int;
    } else if (json['publisher'] is Map && json['publisher']['id'] is int) {
      pubId = json['publisher']['id'] as int;
    }

    List<int> autIds = const [];
    if (json['authorIds'] is List) {
      autIds = (json['authorIds'] as List).whereType<num>().map((e) => e.toInt()).toList();
    } else if (json['authors'] is List) {
      autIds = (json['authors'] as List)
          .whereType<Map>()
          .map((m) => m['id'])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList();
    }

    List<int> genIds = const [];
    if (json['genreIds'] is List) {
      genIds = (json['genreIds'] as List).whereType<num>().map((e) => e.toInt()).toList();
    } else if (json['genres'] is List) {
      genIds = (json['genres'] as List)
          .whereType<Map>()
          .map((m) => m['id'])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList();
    }

    return Book(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
      publisherId: pubId,
      authorIds: autIds,
      genreIds: genIds,
      copiesTotal: json['copiesTotal'] as int? ?? 0,
      copiesAvailable: json['copiesAvailable'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}