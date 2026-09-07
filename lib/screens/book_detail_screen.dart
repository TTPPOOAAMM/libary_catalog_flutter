import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Книга #$bookId')),
      body: FutureBuilder<Book?>(
        future: context.read<BookRepository>().findById(bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snapshot.data;
          if (book == null) {
            return const Center(child: Text('Книга не найдена'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(book.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text('ISBN: ${book.isbn}'),
                    Text('Год издания: ${book.year}'),
                    Text('Количество страниц: ${book.pages}'),
                    Text('Издательство: №${book.publisherId}'),
                    Text('Доступно экземпляров: ${book.copiesAvailable} / ${book.copiesTotal}'),
                    if (book.isDeleted) ...[
                      const SizedBox(height: 8),
                      Text('Удалена: ${book.deletedAt}', style: const TextStyle(color: Colors.red)),
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