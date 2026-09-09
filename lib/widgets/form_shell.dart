import 'package:flutter/material.dart';

class FormShell extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final bool isModified;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final List<Widget> children;

  const FormShell({
    super.key,
    required this.title,
    required this.formKey,
    required this.isModified,
    required this.onSubmit,
    required this.onCancel,
    required this.children,
    this.isLoading = false,
  });

  Future<bool> _confirmLeave(BuildContext context) async {
    if (!isModified) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Вы уверены, что хотите покинуть страницу? Внесённые данные будут потеряны.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Уйти')),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isModified,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmLeave(context) && context.mounted) {
                onCancel();
              }
            },
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...children,
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      if (await _confirmLeave(context) && context.mounted) {
                                        onCancel();
                                      }
                                    },
                                    child: const Text('Отмена'),
                                  ),
                                  const SizedBox(width: 16),
                                  FilledButton(
                                    onPressed: onSubmit,
                                    child: const Text('Сохранить'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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