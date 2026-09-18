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
    required this.isLoading,
    required this.onSubmit,
    required this.onCancel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Отмена',
          onPressed: onCancel,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Сохранить'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
