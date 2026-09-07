class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (country != null && country!.isNotEmpty) params['country'] = country!;
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    params['page'] = page.toString();
    params['size'] = size.toString();
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory AuthorQuery.fromQueryParams(Map<String, String> params) {
    var sortField = 'lastName';
    var sortAsc = true;
    if (params.containsKey('sort')) {
      final parts = params['sort']!.split(',');
      sortField = parts[0];
      if (parts.length > 1 && parts[1].toLowerCase() == 'desc') sortAsc = false;
    }
    return AuthorQuery(
      search: params['search'] ?? '',
      country: params['country'],
      sortField: sortField,
      sortAscending: sortAsc,
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          country == other.country &&
          sortField == other.sortField &&
          sortAscending == other.sortAscending &&
          page == other.page &&
          size == other.size &&
          includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        country,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}