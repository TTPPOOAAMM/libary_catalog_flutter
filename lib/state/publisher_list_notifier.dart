import 'package:flutter/foundation.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/publisher_repository.dart';
import 'book_list_notifier.dart' show LoadStatus;

class PublisherListNotifier extends ChangeNotifier {
  final PublisherRepository _repository;
  PublisherListNotifier(this._repository);

  PublisherQuery _query = const PublisherQuery();
  PageResult<Publisher> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  PublisherQuery get query => _query;
  PageResult<Publisher> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить издательства: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> setQuerySilently(PublisherQuery query) async {
    if (_query == query && _status == LoadStatus.success) return;
    _query = query;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void selectAll(bool select) {
    if (select) {
      _selected.addAll(_result.items.map((p) => p.id));
    } else {
      _selected.clear();
    }
    notifyListeners();
  }
}