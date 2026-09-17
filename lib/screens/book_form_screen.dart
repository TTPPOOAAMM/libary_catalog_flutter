import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../widgets/form_shell.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _totalController = TextEditingController();
  final _availableController = TextEditingController();

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  List<Publisher> _publishers = [];
  List<Author> _authors = [];
  List<Genre> _allGenres = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isModified = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _loadDependenciesAndBook();
  }

  Future<void> _loadDependenciesAndBook() async {
    try {
      final pubRepo = context.read<PublisherRepository>();
      final autRepo = context.read<AuthorRepository>();
      final genRepo = context.read<GenreRepository>();
      final bookRepo = context.read<BookRepository>();

      final pubs = await pubRepo.findAll();
      final auts = await autRepo.findAll();
      final gens = await genRepo.findAll();

      Book? book;
      if (widget.id != null) {
        book = await bookRepo.findById(widget.id!);
      }

      if (!mounted) return;
      setState(() {
        _publishers = pubs;
        _authors = auts;
        _allGenres = gens;

        if (book != null) {
          _titleController.text = book.title;
          _isbnController.text = book.isbn;
          _yearController.text = book.year.toString();
          _pagesController.text = book.pages.toString();
          _totalController.text = book.copiesTotal.toString();
          _availableController.text = book.copiesAvailable.toString();
          _publisherId = book.publisherId;
          _authorIds = [...book.authorIds];
          _genreIds = [...book.genreIds];
        } else if (_publishers.isNotEmpty) {
          _publisherId = _publishers.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _totalController.dispose();
    _availableController.dispose();
    super.dispose();
  }

  void _markModified() {
    if (!_isModified) setState(() => _isModified = true);
  }

  List<Genre> get _availableGenres {
    if (_publisherId == 1) return _allGenres.where((g) => g.id == 1 || g.id == 3).toList();
    if (_publisherId == 2) return _allGenres.where((g) => g.id == 1 || g.id == 2).toList();
    return _allGenres;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final total = int.tryParse(_totalController.text.trim()) ?? 0;
    final avail = int.tryParse(_availableController.text.trim()) ?? 0;
    if (avail > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Доступных копий не может быть больше, чем всего')),
      );
      return;
    }

    final item = Book(
      id: widget.id ?? 0,
      title: _titleController.text.trim(),
      isbn: _isbnController.text.trim(),
      year: int.tryParse(_yearController.text.trim()) ?? 0,
      pages: int.tryParse(_pagesController.text.trim()) ?? 0,
      publisherId: _publisherId ?? 1,
      authorIds: _authorIds,
      genreIds: _genreIds,
      copiesTotal: total,
      copiesAvailable: avail,
    );

    setState(() => _isSaving = true);

    try {
      final bookRepo = context.read<BookRepository>();
      if (widget.id != null) {
        await bookRepo.update(item);
      } else {
        await bookRepo.create(item);
      }
      if (!mounted) return;
      setState(() => _isModified = false);
      context.go('/books');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormShell(
      title: widget.id == null ? 'Новая книга' : 'Редактирование книги #${widget.id}',
      formKey: _formKey,
      isModified: _isModified,
      isLoading: _isLoading,
      onSubmit: _isSaving ? () {} : _submit,
      onCancel: () => context.go('/books'),
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Название книги',
            border: const OutlineInputBorder(),
            errorText: _serverErrors['title'],
          ),
          validator: (v) {
            if (_serverErrors['title'] != null) return _serverErrors['title'];
            return V.combine([V.required(), V.length(min: 2, max: 250)])(v);
          },
          onChanged: (_) {
            if (_serverErrors.containsKey('title')) {
              setState(() => _serverErrors.remove('title'));
            }
            _markModified();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _isbnController,
          decoration: InputDecoration(
            labelText: 'ISBN',
            border: const OutlineInputBorder(),
            errorText: _serverErrors['isbn'],
          ),
          validator: (v) {
            if (_serverErrors['isbn'] != null) return _serverErrors['isbn'];
            return V.combine([V.required(), V.isbn()])(v);
          },
          onChanged: (_) {
            if (_serverErrors.containsKey('isbn')) {
              setState(() => _serverErrors.remove('isbn'));
            }
            _markModified();
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  labelText: 'Год издания',
                  border: const OutlineInputBorder(),
                  errorText: _serverErrors['year'],
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (_serverErrors['year'] != null) return _serverErrors['year'];
                  return V.combine([V.required(), V.integer(min: 1450, max: 2026)])(v);
                },
                onChanged: (_) {
                  if (_serverErrors.containsKey('year')) {
                    setState(() => _serverErrors.remove('year'));
                  }
                  _markModified();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _pagesController,
                decoration: InputDecoration(
                  labelText: 'Страниц',
                  border: const OutlineInputBorder(),
                  errorText: _serverErrors['pages'],
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (_serverErrors['pages'] != null) return _serverErrors['pages'];
                  return V.combine([V.required(), V.integer(min: 1, max: 10000)])(v);
                },
                onChanged: (_) {
                  if (_serverErrors.containsKey('pages')) {
                    setState(() => _serverErrors.remove('pages'));
                  }
                  _markModified();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _publisherId,
          decoration: const InputDecoration(labelText: 'Издательство (1:N)', border: OutlineInputBorder()),
          items: _publishers
              .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.city})')))
              .toList(),
          onChanged: (val) {
            _markModified();
            setState(() {
              _publisherId = val;
              final allowed = _availableGenres.map((g) => g.id).toSet();
              _genreIds.removeWhere((id) => !allowed.contains(id));
            });
          },
          validator: (v) => v == null ? 'Выберите издательство' : null,
        ),
        const SizedBox(height: 16),
        FormField<List<int>>(
          initialValue: _authorIds,
          validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы одного автора' : null,
          builder: (state) => InputDecorator(
            decoration: InputDecoration(
              labelText: 'Авторы (M:N)',
              border: const OutlineInputBorder(),
              errorText: state.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _authors.map((a) {
                final selected = _authorIds.contains(a.id);
                return FilterChip(
                  label: Text(a.fullName),
                  selected: selected,
                  onSelected: (val) {
                    _markModified();
                    setState(() {
                      val ? _authorIds.add(a.id) : _authorIds.remove(a.id);
                      state.didChange(_authorIds);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FormField<List<int>>(
          initialValue: _genreIds,
          validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы один жанр' : null,
          builder: (state) => InputDecorator(
            decoration: InputDecoration(
              labelText: 'Жанры (каскадно фильтруются издательством)',
              border: const OutlineInputBorder(),
              errorText: state.errorText,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableGenres.map((g) {
                final selected = _genreIds.contains(g.id);
                return FilterChip(
                  label: Text(g.name),
                  selected: selected,
                  onSelected: (val) {
                    _markModified();
                    setState(() {
                      val ? _genreIds.add(g.id) : _genreIds.remove(g.id);
                      state.didChange(_genreIds);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(labelText: 'Всего экземпляров', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: V.combine([V.required(), V.integer(min: 0, max: 1000)]),
                onChanged: (_) => _markModified(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _availableController,
                decoration: const InputDecoration(labelText: 'Доступно', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: V.combine([V.required(), V.integer(min: 0, max: 1000)]),
                onChanged: (_) => _markModified(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}