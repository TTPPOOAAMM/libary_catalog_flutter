import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import '../widgets/form_shell.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSaving = false;
  bool _isModified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final g = Genre(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    try {
      await context.read<GenreRepository>().create(g);
      if (mounted) {
        setState(() => _isModified = false);
        context.go('/genres');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormShell(
      title: 'Новый жанр',
      formKey: _formKey,
      isModified: _isModified,
      isLoading: false,
      onSubmit: _isSaving ? () {} : _submit,
      onCancel: () => context.go('/genres'),
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Название жанра', border: OutlineInputBorder()),
          validator: V.required(),
          onChanged: (_) => setState(() => _isModified = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
          maxLines: 3,
          onChanged: (_) => setState(() => _isModified = true),
        ),
      ],
    );
  }
}