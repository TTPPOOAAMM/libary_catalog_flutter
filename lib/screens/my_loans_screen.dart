import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../repositories/loan_repository.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  List<Loan> _myLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await context.read<LoanRepository>().findMyLoans();
      if (mounted) setState(() => _myLoans = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _extend(int id) async {
    try {
      await context.read<LoanRepository>().extendLoan(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Срок выдачи успешно продлён на 14 дней!')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось продлить срок: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои книги (Читатель)'),
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
          : _myLoans.isEmpty
              ? const Center(child: Text('У вас нет книг на руках'))
              : ListView.builder(
                  itemCount: _myLoans.length,
                  itemBuilder: (ctx, i) {
                    final l = _myLoans[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: Text(l.bookTitle),
                        subtitle: Text(
                          'Срок сдачи: ${l.dueDate.toString().split(' ')[0]}'
                          '${l.isOverdue ? " (Просрочено!)" : ""}\nПродлений: ${l.extensionCount}',
                        ),
                        trailing: OutlinedButton(
                          onPressed: l.isReturned ? null : () => _extend(l.id),
                          child: const Text('Продлить (+14 дн.)'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}