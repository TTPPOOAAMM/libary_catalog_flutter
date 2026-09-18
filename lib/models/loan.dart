class Loan {
  final int id;
  final int bookId;
  final String bookTitle;
  final int readerId;
  final String readerName;
  final DateTime issuedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final int extensionCount;

  const Loan({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.readerId,
    required this.readerName,
    required this.issuedAt,
    required this.dueDate,
    this.returnedAt,
    this.extensionCount = 0,
  });

  bool get isReturned => returnedAt != null;
  bool get isOverdue => !isReturned && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'readerId': readerId,
        'readerName': readerName,
        'issuedAt': issuedAt.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'returnedAt': returnedAt?.toIso8601String(),
        'extensionCount': extensionCount,
      };

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      bookTitle: json['bookTitle'] as String? ?? 'Книга #${json['bookId']}',
      readerId: json['readerId'] as int? ?? 0,
      readerName: json['readerName'] as String? ?? 'Читатель #${json['readerId']}',
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 14)),
      returnedAt: json['returnedAt'] == null
          ? null
          : DateTime.tryParse(json['returnedAt'] as String),
      extensionCount: json['extensionCount'] as int? ?? 0,
    );
  }
}