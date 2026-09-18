import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';
import '../widgets/form_shell.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isSaving = false;
  bool _isModified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final p = Publisher(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
    );

    try {
      await context.read<PublisherRepository>().create(p);
      if (mounted) {
        setState(() => _isModified = false);
        context.go('/publishers');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormShell(
      title: 'Новое издательство',
      formKey: _formKey,
      isModified: _isModified,
      isLoading: false,
      onSubmit: _isSaving ? () {} : _submit,
      onCancel: () => context.go('/publishers'),
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
              labelText: 'Наименование', border: OutlineInputBorder()),
          validator: V.required(),
          onChanged: (_) => setState(() => _isModified = true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
              labelText: 'Город', border: OutlineInputBorder()),
          validator: V.required(),
          onChanged: (_) => setState(() => _isModified = true),
        ),
      ],
    );
  }
}
