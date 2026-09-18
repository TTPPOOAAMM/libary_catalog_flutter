class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId:
          publisherId == _unset ? this.publisherId : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, dynamic> toApiParams() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (genreId != null) 'genreId': genreId,
        if (publisherId != null) 'publisherId': publisherId,
        if (yearFrom != null) 'yearFrom': yearFrom,
        if (yearTo != null) 'yearTo': yearTo,
        'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
        'page': page,
        'size': size,
        if (includeDeleted) 'includeDeleted': true,
      };

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (genreId != null) params['genreId'] = genreId.toString();
    if (publisherId != null) params['publisherId'] = publisherId.toString();
    if (yearFrom != null) params['yearFrom'] = yearFrom.toString();
    if (yearTo != null) params['yearTo'] = yearTo.toString();
    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    params['page'] = page.toString();
    params['size'] = size.toString();
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory BookQuery.fromQueryParams(Map<String, String> params) {
    var sortField = 'title';
    var sortAsc = true;
    if (params.containsKey('sort')) {
      final parts = params['sort']!.split(',');
      sortField = parts[0];
      if (parts.length > 1 && parts[1].toLowerCase() == 'desc') {
        sortAsc = false;
      }
    }
    return BookQuery(
      search: params['search'] ?? '',
      genreId: int.tryParse(params['genreId'] ?? ''),
      publisherId: int.tryParse(params['publisherId'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: sortField,
      sortAscending: sortAsc,
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }
}
