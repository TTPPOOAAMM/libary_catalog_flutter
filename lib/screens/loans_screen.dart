import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../repositories/loan_repository.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await context.read<LoanRepository>().findAll();
      if (mounted) setState(() => _loans = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _returnLoan(int id) async {
    await context.read<LoanRepository>().returnLoan(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выдачи книг (Библиотекарь)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? const Center(child: Text('Нет активных или закрытых выдач'))
              : ListView.builder(
                  itemCount: _loans.length,
                  itemBuilder: (ctx, i) {
                    final l = _loans[i];
                    return ListTile(
                      leading: Icon(
                        l.isReturned ? Icons.check_circle : (l.isOverdue ? Icons.warning : Icons.book),
                        color: l.isReturned ? Colors.green : (l.isOverdue ? Colors.red : Colors.blue),
                      ),
                      title: Text(l.bookTitle),
                      subtitle: Text('Читатель: ${l.readerName} | До: ${l.dueDate.toString().split(' ')[0]}'),
                      trailing: l.isReturned
                          ? const Chip(label: Text('Возвращена'))
                          : FilledButton.tonal(
                              onPressed: () => _returnLoan(l.id),
                              child: const Text('Принять возврат'),
                            ),
                    );
                  },
                ),
    );
  }
}