import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../repositories/book_repository.dart';

enum LoadStatus { idle, loading, success, error }

class BookListNotifier extends ChangeNotifier {
  final BookRepository _repository;
  BookListNotifier(this._repository);

  BookQuery _query = const BookQuery();
  PageResult<Book> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  BookQuery get query => _query;
  PageResult<Book> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      if (e is NetworkException && e.message.contains('отменён')) {
        return;
      }
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> setQuerySilently(BookQuery query) async {
    if (_query == query && _status == LoadStatus.success) return;
    _query = query;
    _selected.clear();
    await load();
  }

  Future<void> applyQuery(BookQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void selectAll(bool select) {
    if (select) {
      _selected.addAll(_result.items.map((b) => b.id));
    } else {
      _selected.clear();
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}