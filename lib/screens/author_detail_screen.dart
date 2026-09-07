import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Автор #$authorId')),
      body: FutureBuilder<Author?>(
        future: context.read<AuthorRepository>().findById(authorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final author = snapshot.data;
          if (author == null) return const Center(child: Text('Автор не найден'));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(author.fullName, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text('Страна: ${author.country}'),
                    Text('Год рождения: ${author.birthYear}'),
                    if (author.isDeleted) ...[
                      const SizedBox(height: 8),
                      Text('Удалён: ${author.deletedAt}', style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}