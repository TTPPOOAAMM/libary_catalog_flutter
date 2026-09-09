import 'package:flutter/foundation.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../repositories/reader_repository.dart';
import 'book_list_notifier.dart' show LoadStatus;

class ReaderListNotifier extends ChangeNotifier {
  final ReaderRepository _repository;
  ReaderListNotifier(this._repository);

  ReaderQuery _query = const ReaderQuery();
  PageResult<Reader> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ReaderQuery get query => _query;
  PageResult<Reader> get result => _result;
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
      _error = 'Не удалось загрузить читателей: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> setQuerySilently(ReaderQuery query) async {
    if (_query == query && _status == LoadStatus.success) return;
    _query = query;
    _selected.clear();
    await load();
  }

  Future<void> applyQuery(ReaderQuery next) async {
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
      _selected.addAll(_result.items.map((r) => r.id));
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