import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/loan.dart';

abstract class LoanRepository {
  Future<List<Loan>> findAll();
  Future<List<Loan>> findMyLoans();
  Future<Loan> issueLoan(
      {required int bookId, required int readerId, int days = 14});
  Future<Loan> returnLoan(int loanId);
  Future<Loan> extendLoan(int loanId, {int additionalDays = 14});
}

class ApiLoanRepository implements LoanRepository {
  final Dio _dio;
  ApiLoanRepository(this._dio);

  @override
  Future<List<Loan>> findAll() => guard(() async {
        final res = await _dio.get('/loans');
        final data = res.data;
        final list = (data is Map && data['items'] is List)
            ? data['items'] as List
            : (data is List ? data : const []);
        return list
            .whereType<Map<String, dynamic>>()
            .map(Loan.fromJson)
            .toList();
      });

  @override
  Future<List<Loan>> findMyLoans() => guard(() async {
        final res = await _dio.get('/loans/my');
        final data = res.data;
        final list = (data is Map && data['items'] is List)
            ? data['items'] as List
            : (data is List ? data : const []);
        return list
            .whereType<Map<String, dynamic>>()
            .map(Loan.fromJson)
            .toList();
      });

  @override
  Future<Loan> issueLoan(
          {required int bookId, required int readerId, int days = 14}) =>
      guard(() async {
        final res = await _dio.post('/loans', data: {
          'bookId': bookId,
          'readerId': readerId,
          'days': days,
        });
        return Loan.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<Loan> returnLoan(int loanId) => guard(() async {
        final res = await _dio.put('/loans/$loanId/return');
        return Loan.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<Loan> extendLoan(int loanId, {int additionalDays = 14}) =>
      guard(() async {
        final res = await _dio.put('/loans/$loanId/extend', data: {
          'days': additionalDays,
        });
        return Loan.fromJson(res.data as Map<String, dynamic>);
      });
}
