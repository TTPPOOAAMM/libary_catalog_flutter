class ReaderQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ReaderQuery({
    this.search = '',
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  ReaderQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) =>
      ReaderQuery(
        search: search ?? this.search,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? 1,
        size: size ?? this.size,
        includeDeleted: includeDeleted ?? this.includeDeleted,
      );

  Map<String, String> toQueryParams() => {
        if (search.isNotEmpty) 'search': search,
        'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
        'page': page.toString(),
        'size': size.toString(),
        if (includeDeleted) 'includeDeleted': 'true',
      };

  factory ReaderQuery.fromQueryParams(Map<String, String> params) {
    var sortField = 'fullName';
    var sortAsc = true;
    if (params.containsKey('sort')) {
      final p = params['sort']!.split(',');
      sortField = p[0];
      if (p.length > 1 && p[1] == 'desc') sortAsc = false;
    }
    return ReaderQuery(
      search: params['search'] ?? '',
      sortField: sortField,
      sortAscending: sortAsc,
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }
}