import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  final String? from;
  const RegisterScreen({super.key, this.from});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'reader';
  bool _isLoading = false;
  String? _errorMessage;

  PasswordStrength _strength = const PasswordStrength(
    hasMinLength: false,
    hasDigit: false,
    hasSpecialChar: false,
  );

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _strength = PasswordStrength.evaluate(_passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (!_strength.isValid) {
      setState(() =>
          _errorMessage = 'Пароль не отвечает всем требованиям безопасности.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthNotifier>().register(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (!mounted) return;
      final target = (widget.from != null && widget.from!.isNotEmpty)
          ? Uri.decodeComponent(widget.from!)
          : '/books';
      context.go(target);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Ошибка регистрации: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCheckRow(bool valid, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: valid ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: valid ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация читателя'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Новый пользователь',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                            labelText: 'ФИО', border: OutlineInputBorder()),
                        validator: V.combine(
                            [V.required(), V.length(min: 3, max: 100)]),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            labelText: 'Логин', border: OutlineInputBorder()),
                        validator: V
                            .combine([V.required(), V.length(min: 3, max: 30)]),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: 'Email', border: OutlineInputBorder()),
                        validator: V.combine([V.required(), V.email()]),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                            labelText: 'Роль', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'reader', child: Text('Читатель')),
                          DropdownMenuItem(
                              value: 'librarian', child: Text('Библиотекарь')),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedRole = val ?? 'reader'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                        ),
                        validator: V.required('Введите пароль'),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Требования к надежности пароля:',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            _buildCheckRow(
                                _strength.hasMinLength, 'Минимум 8 символов'),
                            _buildCheckRow(
                                _strength.hasDigit, 'Минимум одна цифра'),
                            _buildCheckRow(_strength.hasSpecialChar,
                                'Минимум один спецсимвол (!@#\$%...)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Зарегистрироваться'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
