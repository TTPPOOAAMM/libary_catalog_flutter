import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../widgets/form_shell.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();

  DateTime _issuedAt = DateTime.now();
  bool _cardActive = true;
  bool _isLoading = true;
  bool _isModified = false;
  String? _emailServerError;

  @override
  void initState() {
    super.initState();
    _loadReader();
  }

  Future<void> _loadReader() async {
    if (widget.id != null) {
      final reader = await context.read<ReaderRepository>().findById(widget.id!);
      if (reader != null) {
        _nameController.text = reader.fullName;
        _emailController.text = reader.email;
        _phoneController.text = reader.phone;
        _cardNumberController.text = reader.card.cardNumber;
        _issuedAt = reader.card.issuedAt;
        _cardActive = reader.card.isActive;
      }
    } else {
      _cardNumberController.text = 'LC-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  void _markModified() {
    if (!_isModified) setState(() => _isModified = true);
  }

  Future<void> _submit() async {
    setState(() => _emailServerError = null);
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ReaderRepository>();
    final unique = await repo.isEmailUnique(_emailController.text.trim(), excludeId: widget.id);
    if (!unique) {
      setState(() => _emailServerError = 'Читатель с таким адресом уже зарегистрирован');
      _formKey.currentState!.validate();
      return;
    }

    final item = Reader(
      id: widget.id ?? 0,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      card: LibraryCard(
        cardNumber: _cardNumberController.text.trim(),
        issuedAt: _issuedAt,
        isActive: _cardActive,
      ),
    );

    if (widget.id != null) {
      await repo.update(item);
    } else {
      await repo.create(item);
    }

    setState(() => _isModified = false);
    if (mounted) context.go('/readers');
  }

  @override
  Widget build(BuildContext context) {
    return FormShell(
      title: widget.id == null ? 'Регистрация читателя' : 'Редактирование читателя #${widget.id}',
      formKey: _formKey,
      isModified: _isModified,
      isLoading: _isLoading,
      onSubmit: _submit,
      onCancel: () => context.go('/readers'),
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'ФИО читателя', border: OutlineInputBorder()),
          validator: V.combine([V.required(), V.length(min: 3, max: 150)]),
          onChanged: (_) => _markModified(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Электронная почта',
            border: const OutlineInputBorder(),
            errorText: _emailServerError,
          ),
          validator: (v) {
            if (_emailServerError != null) return _emailServerError;
            return V.combine([V.required(), V.email()])(v);
          },
          onChanged: (_) {
            if (_emailServerError != null) setState(() => _emailServerError = null);
            _markModified();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Номер телефона', border: OutlineInputBorder()),
          validator: V.combine([V.required(), V.length(min: 6, max: 20)]),
          onChanged: (_) => _markModified(),
        ),
        const SizedBox(height: 24),
        const Text('Читательский билет (связь 1:1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(labelText: 'Номер билета', border: OutlineInputBorder()),
          validator: V.combine([V.required(), V.length(min: 4, max: 20)]),
          onChanged: (_) => _markModified(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Билет активен'),
          value: _cardActive,
          onChanged: (val) {
            _markModified();
            setState(() => _cardActive = val);
          },
        ),
      ],
    );
  }
}