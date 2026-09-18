import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthNotifier>().currentRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступ ограничен'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Ошибка 403: Доступ запрещён',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ваша текущая роль («${role.label}») не имеет разрешений для просмотра этого раздела или выполнения данной операции.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/books'),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('В каталог книг'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/my-loans'),
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Мои выдачи'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
