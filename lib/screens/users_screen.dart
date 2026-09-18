import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../state/auth_notifier.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await context.read<UserRepository>().find();
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(User user, UserRole newRole) async {
    try {
      await context.read<UserRepository>().updateRole(user.id, newRole);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка изменения роли: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями (Администратор)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                const Icon(Icons.developer_mode, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '[Тест ПР5 / Требование 17]: Подменить роль в UI на Читателя (проверка 403 при серверном отказе):',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await context.read<AuthNotifier>().simulateDevToolsRoleChange(UserRole.reader);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Роль в UI подменена на "reader"!')),
                      );
                    }
                  },
                  child: const Text('Подменить роль'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final u = _users[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(u.username.substring(0, 1).toUpperCase())),
                            title: Text(u.fullName),
                            subtitle: Text('${u.username} • ${u.email}'),
                            trailing: DropdownButton<UserRole>(
                              value: u.role,
                              items: UserRole.values
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                                  .toList(),
                              onChanged: (newR) {
                                if (newR != null && newR != u.role) _changeRole(u, newR);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}