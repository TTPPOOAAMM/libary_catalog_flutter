import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../widgets/form_shell.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _birthYearController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final a = await context.read<AuthorRepository>().findById(widget.id!);
      if (a != null && mounted) {
        _firstNameController.text = a.firstName;
        _lastNameController.text = a.lastName;
        _countryController.text = a.country;
        _birthYearController.text = a.birthYear.toString();
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final a = Author(
      id: widget.id ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _countryController.text.trim(),
      birthYear: int.tryParse(_birthYearController.text.trim()) ?? 1900,
    );

    try {
      final repo = context.read<AuthorRepository>();
      widget.id != null ? await repo.update(a) : await repo.create(a);
      if (mounted) {
        setState(() => _isModified = false);
        context.go('/authors');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormShell(
      title: widget.id == null ? 'Новый автор' : 'Редактирование автора',
      formKey: _formKey,
      isModified: _isModified,
      isLoading: _isLoading,
      onSubmit: _isSaving ? () {} : _submit,
      onCancel: () => context.go('/authors'),
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
              labelText: 'Имя', border: OutlineInputBorder()),
          validator: V.required(),
          onChanged: (_) => setState(() => _isModified = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
              labelText: 'Фамилия', border: OutlineInputBorder()),
          validator: V.required(),
          onChanged: (_) => setState(() => _isModified = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
              labelText: 'Страна', border: OutlineInputBorder()),
          validator: V.required(),
          onChanged: (_) => setState(() => _isModified = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _birthYearController,
          decoration: const InputDecoration(
              labelText: 'Год рождения', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          validator: V.combine([V.required(), V.integer(min: 0, max: 2026)]),
          onChanged: (_) => setState(() => _isModified = true),
        ),
      ],
    );
  }
}
